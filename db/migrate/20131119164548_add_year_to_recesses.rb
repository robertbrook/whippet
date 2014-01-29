class AddYearToRecesses < ActiveRecord::Migration
  def self.up
    add_column :recesses, :year, :integer
  end
  
  def self.down
    remove_column :recesses, :year
  end
end