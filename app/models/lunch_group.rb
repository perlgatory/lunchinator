class LunchGroup < ApplicationRecord
  enum status: {
      open: 'open',
      assembled: 'assembled',
      departed: 'departed'
  }

  def destination_string
    self.destination || 'lunch'
  end
end
