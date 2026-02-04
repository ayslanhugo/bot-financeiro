class AddSpouseIdToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :spouse_telegram_id, :string
  end
end
