class StoreUserId < ActiveRecord::Migration[5.1]
  def change

    add_column :lunch_groups, :initiating_user_id, :integer, null: true
  end
end
