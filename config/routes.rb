Rails.application.routes.draw do
  get '/' => 'application#test'
  post '/lunch' => 'application#lunch'
  post '/delete-lunch' => 'application#delete_lunch'
  post '/interactive' => 'application#interactive'
end
