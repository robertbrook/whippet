module Diffable
  def self.included base
    base.send :include, InstanceMethods
    base.extend ClassMethods
  end
  
  module InstanceMethods
    def diff(other)
      check_class_compatibility(self, other)
      
      self_attribs = self.get_attributes(self.class.excluded_from_copy)
      other_attribs = other.get_attributes(other.class.excluded_from_copy)
      
      #compare the simple values
      change = compare_attributes(self_attribs, other_attribs, self)
      
      #analyse the time_blocks
      change = analyze_subobjects(self, other, change)
      
      #the last bit - no change, no report; simples
      other.class.conditional_fields.each do |key|
        change[key.to_sym] = eval("other.#{key}") unless change.empty?
      end
      change
    end
    
    def get_attributes(excluded)
      attribs = attributes.dup
      attribs.delete_if { |key, value| excluded.include?(key) or key == "id" }
    end
    
    def reflected_names(obj)
      classes = obj.reflections
      class_names = []
      classes.each do |key, cl|
        if cl.association_class != ActiveRecord::Associations::BelongsToAssociation \
           and eval(cl.class_name).respond_to?("diffable")
          class_names << key
        end
      end
      class_names
    end
    
    private
    
    def check_class_compatibility(current, other)
      if current.class.superclass == ActiveRecord::Base || other.class.superclass == ActiveRecord::Base
        if other.class != current.class || other.class.superclass != current.class
          raise "Unable to compare #{current.class} to #{other.class}"
        end
      else
        if current.class != other.class && other.class.superclass != current.class.superclass
          raise "Unable to compare #{current.class} to #{other.class}"
        end
      end
    end
    
    def find_in_array_by_ident(arr, value)
      arr.select { |x| eval(%Q|x.#{x.class.unique_within_group}|) == value }.first
    end
    
    def map_obj_idents(obj)
      obj.map { |x| x.attributes[x.class.unique_within_group] }
    end
    
    def ident_in_list?(ident, ident_list)
      return true if ident_list.include?(ident)
      false
    end
    
    def compare_current_subs(current_obj_idents, previous_obj_idents, current_subs, previous_subs)
      objects = []
      current_obj_idents.each do |idnt|
        current_sub = find_in_array_by_ident(current_subs, idnt)
        previous_sub = find_in_array_by_ident(previous_subs, idnt)
        
        if ident_in_list?(idnt, previous_obj_idents)
          #pre-existing thing, compare the differences...
          current_attribs = current_sub.get_attributes(current_sub.class.excluded_from_copy)
          previous_attribs = previous_sub.get_attributes(previous_sub.class.excluded_from_copy)
          
          #compare the simple values
          obj = compare_attributes(current_attribs, previous_attribs, current_sub)
          
          #analyse the time_blocks
          obj = analyze_subobjects(current_sub, previous_sub, obj)
          
          #...and only store if something's changed
          unless obj.empty?
            obj[:change_type] = "modified"
            objects << obj
          end
        else
          #a new thing, just need to note its arrival
          unique_field = current_sub.class.unique_within_group
          objects << {unique_field.to_sym => eval("current_sub.#{unique_field}"), :change_type => "new"}
        end
      end
      objects
    end
    
    def preserve_deleted_by_ident(deleted_idents, previous_subs, previous_obj, sub)
      objects = []
      deleted_idents.each do |ident|
        previous_sub = find_in_array_by_ident(eval("previous_obj.#{sub}.to_a"), ident)
        obj = preserve_deleted_obj(previous_sub)
        objects << obj
      end
      objects
    end
    
    def compare_attributes(current, previous, current_obj, change={})
      previous.each do |key, value|
        change[key.to_sym] = value if value != current[key]
      end
      unless change.empty?
        unique_field = current_obj.class.unique_within_group
        change[unique_field.to_sym] = eval("current_obj.#{unique_field}")
      end
      change
    end
    
    def analyze_subobjects(current_obj, previous_obj, change={})
      #need both - comparable objects need not have the same reflections
      current_subs = reflected_names(current_obj)
      previous_subs = reflected_names(previous_obj)
      
      #things that are available to the current object
      current_subs.each do |sub|
        objects = []
        current_objects = current_obj.association(sub).target
        previous_objects = previous_obj.respond_to?(sub) ? eval("previous_obj.#{sub}.to_a") : []
        current_obj_idents = map_obj_idents(current_objects)
        previous_obj_idents = map_obj_idents(previous_objects)
        
        #loop through the ids in the current block
        objects += compare_current_subs(current_obj_idents, previous_obj_idents, current_objects, previous_objects)
        
        #look for ids that only exist in the previous block
        objects += preserve_deleted_by_ident((previous_obj_idents - current_obj_idents), previous_subs, previous_obj, sub)
        
        #update time_blocks if any changes were found
        change[sub] = objects unless objects.empty?
      end
      
      #things that are only available to the previous object
      (previous_subs - current_subs).each do |sub|
        objects = []
        previous_obj_idents = map_obj_idents(previous_obj)
        objects += preserve_deleted_by_ident(previous_obj_idents, (previous_subs - current_subs), previous_obj, sub)
        change[sub] = objects unless objects.empty?
      end
      change
    end
    
    def preserve_deleted_obj(deleted, excluded_from_copy=self.class.excluded_from_copy)
      obj = {}
      #get attributes of object marked for deletion...
      attribs = deleted.get_attributes(deleted.class.excluded_from_copy)
      #...and copy them for preservation
      attribs.keys.each do |att|
        value = nil
        if deleted.respond_to?(att)
          value = eval("deleted.#{att}")
        end
        
        obj[att.to_sym] = value unless value.nil?
      end
      
      #look to see if our target object has sub-objects of its own
      previous_sub_keys = reflected_names(deleted)
      
      #preserve subs
      obj = preserve_deleted_subs(previous_sub_keys, deleted, obj)
      
      unless obj.empty?
        deleted.class.conditional_fields.each do |key|
          obj[key.to_sym] = eval("deleted.#{key}") unless obj.empty?
        end
        obj[:change_type] = "deleted"
      end
      obj
    end
    
    def preserve_deleted_subs(keys, deleted, change={})
      keys.each do |sub|
        subs = []
        previous_subs = deleted.respond_to?(sub) ? eval("deleted.#{sub}.to_a") : []
        previous_subs.each do |deleted_sub|  
          preserved = preserve_deleted_obj(deleted_sub)
          subs << preserved
        end
        change[sub] = subs unless subs.empty?
      end
      change
    end
  end
  
  module ClassMethods
    attr_accessor :excluded_from_copy, :unique_within_group, :conditional_fields, :diffable
    
    @diffable = true
    
    def set_excluded_from_copy(*h)
      @excluded_from_copy = ["history"]
      h.each { |key| eval(%Q|@excluded_from_copy << "#{key.to_s}"|) }
    end
    
    def set_conditional_fields(*h)
      @conditional_fields = []
      h.each { |key| eval(%Q|@conditional_fields << "#{key.to_s}"|) }
    end
    
    def set_unique_within_group(value)
      eval(%Q|@unique_within_group = "#{value.to_s}"|)
    end
  end
end