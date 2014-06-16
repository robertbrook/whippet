class CreateOralQuestions < ActiveRecord::Migration
  def self.up
    create_table :oral_questions do |t|
      t.string  :date_string
      t.text    :complete
    end
  end
  
  def self.down
    drop_table :oral_questions
  end
end