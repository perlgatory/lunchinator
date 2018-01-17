class AddMessageIdToLunchGroup < ActiveRecord::Migration[5.1]
  def change
    add_column :lunch_groups, :message_id, :text
  end
end
