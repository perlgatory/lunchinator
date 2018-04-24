class CreateLunchGroups < ActiveRecord::Migration[5.1]
  def up
    execute <<-SQL
      CREATE TYPE lunch_group_status AS ENUM ('open', 'assembled', 'departed');
    SQL

    create_table :lunch_groups do |t|
      t.column :status, :lunch_group_status, index: true
      t.text :channel_id
      t.datetime :departure_time

      t.timestamps
    end
  end
  def down
    drop_table :lunch_groups

    execute <<-SQL
      DROP TYPE lunch_group_status;
    SQL
  end
end
