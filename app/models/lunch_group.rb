class LunchGroup < ApplicationRecord
  enum status: {
      open: 'open',
      assembled: 'assembled',
      departed: 'departed'
  }
end
