class AddIndexesToExpenses < ActiveRecord::Migration[8.0]
  def change
    add_index :expenses, :user_id, if_not_exists: true
    
    add_index :expenses, :date, if_not_exists: true
    
    add_index :expenses, [:user_id, :date], if_not_exists: true
  end
end