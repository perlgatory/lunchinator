class PopulatePlacesTable < ApplicationJob
  def perform
    client = GooglePlaces::Client.new(ENV['GOOGLE_API_KEY'])
    spots = client.spots(38.641230, -90.265204, :types => 'restaurant', :radius => 1010, :multipage => 1).map{ |spot| {name: spot.name, google_places_id: spot.id }}
    spots.each { |spot| Place.where(spot).first_or_create }
  end
end
