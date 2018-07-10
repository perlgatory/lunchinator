class AddDestinationToLunchGroups < ActiveRecord::Migration[5.1]
  def change
    add_column :lunch_groups, :destination, :text
  end
end
