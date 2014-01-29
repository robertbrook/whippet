class RenameSittingFridayCol < ActiveRecord::Migration
  def self.up
    rename_column :sitting_fridays, :sitting_friday, :date
  end
  
  def self.down
    rename_column :sitting_fridays, :date, :sitting_friday
  end
end