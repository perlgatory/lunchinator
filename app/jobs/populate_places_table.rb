class PopulatePlacesTable < ApplicationJob
  def perform
    client = GooglePlaces::Client.new(ENV['GOOGLE_API_KEY'])
    client.spots(38.641230, -90.265204, :types => 'restaurant', :radius => 1500)
    #TODO: fill database with results
  end
end
