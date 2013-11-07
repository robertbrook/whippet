#encoding: utf-8

class CalendarDay < ActiveRecord::Base
  def has_time_blocks?
    if respond_to?(:time_blocks)
      return true unless time_blocks.empty?
    end
    false
  end
  
  def excluded_fields
    ["meta", "history"]
  end
  
  def unique_id_within_group
    "ident"
  end
  
  def becomes(klass)
    became = klass.new
    self.instance_variables.each do |var|
      became.instance_variable_set("#{var}", self.instance_variable_get(var))
    end
    became.type = klass.name
    became
  end
  
  def parent_class_array(obj)
    obj.class.reflect_on_all_associations(:belongs_to).map { |x| x.name }
  end
  
  def source_docs
    pdfs = [meta["pdf_info"]["filename"]]
    if time_blocks
      sub_docs = time_blocks.map { |block| block.business_items.map { |item| (item.meta && item.meta["pdf_info"]) ? item.meta["pdf_info"]["filename"] : nil }}
      pdfs += sub_docs.flatten
    end
    pdfs.uniq.delete_if { |x| x.nil? }
  end
  
  def diff(other)
    unless other.is_a?(CalendarDay)
      raise "Unable to compare #{self.class} to #{other.class}"
    end
    
    self_attribs = self.get_attributes(self.excluded_fields)
    other_attribs = other.get_attributes(other.excluded_fields)
    
    #compare the simple values
    change = compare_attributes(self_attribs, other_attribs, self)
    
    #analyse the time_blocks
    unless @analyze_subobjects == false
      change = analyze_subobjects(self, other, change)
    end
    
    #the last bit - no change, no report; simples
    change[:meta] = other.meta unless change.empty?
    change
  end
  
  def get_attributes(excluded)
    attribs = attributes.dup
    attribs.delete_if { |key, value| excluded.include?(key) or key == "id" }
  end
  
  
  private
  
  def find_in_array_by_ident(arr, value)
    arr.select { |x| x.ident == value }.first
  end
  
  def map_obj_idents(obj)
    obj.map { |x| x.attributes[x.unique_id_within_group] }
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
        current_attribs = current_sub.get_attributes(current_sub.excluded_fields)
        previous_attribs = previous_sub.get_attributes(previous_sub.excluded_fields)
        
        #compare the simple values
        obj = compare_attributes(current_attribs, previous_attribs, current_sub)
        
        #analyse the time_blocks
        unless @analyze_subobjects == false
          obj = analyze_subobjects(current_sub, previous_sub, obj)
        end
        
        #...and only store if something's changed
        unless obj.empty?
          obj[:change_type] = "modified"
          objects << obj
        end
      else
        #a new thing, just need to note its arrival
        objects << {unique_id_within_group.to_sym => eval("current_sub.#{unique_id_within_group}"), :change_type => "new"}
      end
    end
    objects
  end
  
  def preserve_deleted_subs(deleted_idents, previous_subs, previous_obj, sub)
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
      change[current_obj.unique_id_within_group.to_sym] = eval("current_obj.#{current_obj.unique_id_within_group}")
    end
    change
  end
  
  def analyze_subobjects(current_obj, previous_obj, change={})
    #need both - comparable objects need not have the same reflections
    current_subs = current_obj.reflections.keys
    current_subs.delete_if { |key, _| parent_class_array(current_obj).include?(key) }
    previous_subs = previous_obj.reflections.keys
    previous_subs.delete_if { |key, _| parent_class_array(previous_obj).include?(key) }
    
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
      objects += preserve_deleted_subs((previous_obj_idents - current_obj_idents), previous_subs, previous_obj, sub)
      
      #update time_blocks if any changes were found
      change[sub] = objects unless objects.empty?
    end
    
    #things that are only available to the previous object
    (previous_subs - current_subs).each do |sub|
      objects = []
      previous_obj_idents = map_obj_idents(previous_obj)
      objects += preserve_deleted_subs(previous_obj_idents, (previous_subs - current_subs), previous_obj, sub)
      change[sub] = objects unless objects.empty?
    end
    change
  end
  
  def preserve_deleted_obj(deleted, excluded_fields=@excluded_fields)
    obj = {}
    #get attributes of object marked for deletion...
    attribs = deleted.get_attributes(deleted.excluded_fields)
    #...and copy them for preservation
    attribs.keys.each do |att|
      value = nil
      if deleted.respond_to?(att)
        value = eval("deleted.#{att}")
      end
      
      obj[att.to_sym] = value unless value.nil?
    end
    
    #look to see if our target object has sub-objects of its own
    previous_sub_keys = deleted.reflections.keys
    previous_sub_keys.delete_if { |key, _| parent_class_array(deleted).include?(key) }
    
    #preserve subs
    previous_sub_keys.each do |sub|
      subs = []
      previous_subs = deleted.respond_to?(sub) ? eval("deleted.#{sub}.to_a") : []
      previous_subs.each do |deleted_sub|  
        preserved = preserve_deleted_obj(deleted_sub)
        subs << preserved
      end
      obj[sub] = subs unless subs.empty?
    end
    
    unless obj.empty?
      obj[:meta] = deleted.meta 
      obj[:change_type] = "deleted"
    end
    obj
  end
end

class SittingDay < CalendarDay
  has_many :time_blocks, :dependent => :destroy
end

class NonSittingDay < CalendarDay
end
