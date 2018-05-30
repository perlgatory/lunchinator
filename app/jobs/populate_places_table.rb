class PopulatePlacesTable < ApplicationJob
  def perform
    client = GooglePlaces::Client.new(ENV['GOOGLE_API_KEY'])
    client.spots(38.641230, -90.265204, :types => 'restaurant', :radius => 1010, :multipage => 1)
    #TODO: fill database with results
    # Multipage only allows 60 entries max
  end
end
