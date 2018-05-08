class AddPlacesTable < ActiveRecord::Migration[5.1]
  def change
    create_table :places do |t|
      t.text :name, index: true
      t.text :google_places_id, index: true
    end
  end
end
