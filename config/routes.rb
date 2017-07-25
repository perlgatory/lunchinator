Rails.application.routes.draw do
  get '/' => 'application#test'
  post '/lunch' => 'application#lunch'
end
