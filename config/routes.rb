Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "games#index"

  resources :games, only: [ :index, :new, :create, :show, :destroy ] do
    post "bid", on: :member
  end
end
