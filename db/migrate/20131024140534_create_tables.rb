class CreateTables < ActiveRecord::Migration
  def self.up
    create_table :calendar_days do |t|
      t.string  :type
      t.string  :ident
      t.date    :date
      t.string  :note
      t.boolean :accepted
      t.boolean :is_provisional
      t.json    :history
      t.json    :meta
    end
    
    add_index(:calendar_days, :ident)
    
    create_table :time_blocks do |t|
      t.integer :sitting_day_id
      t.string  :ident
      t.integer :time_as_number
      t.string  :title
      t.string  :note
      t.integer :position
      t.json    :meta
    end
    
    add_index(:time_blocks, :ident)
    
    create_table :business_items do |t|
      t.integer :time_block_id
      t.string  :ident
      t.text    :description
      t.integer :position
      t.string  :note
      t.json    :meta
    end
    
    add_index(:business_items, :ident)
    
    create_table :speaker_lists do |t|
      t.integer :time_block_id
      t.string  :speaker
      t.json    :meta
    end
    
    create_table :recesses do |t|
      t.string  :name
      t.date    :start_date
      t.date    :finish_date
      t.json    :meta
    end
    
    create_table :sitting_fridays do |t|
      t.date    :sitting_friday
      t.json    :meta
    end
  end
  
  def self.down
    drop_table :sitting_fridays
    drop_table :recesses
    drop_table :speaker_lists
    remove_index(:business_items, :ident)
    drop_table :business_items
    remove_index(:time_blocks, :ident)
    drop_table :time_blocks
    remove_index(:calendar_days, :ident)
    drop_table :calendar_days
  end
end