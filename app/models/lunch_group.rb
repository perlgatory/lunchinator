class LunchGroup < ApplicationRecord
  enum status: {
      open: 'open',
      assembled: 'assembled',
      departed: 'departed'
  }

  def destination_string
    self.destination || 'lunch'
  end

  def initiating_user
    SlackUser.new(self.initiating_user_id)
  end
end
