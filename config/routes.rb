require_relative "../app.rb"

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  # Legacy Sinatra routes (mounted at root)
  mount MyApp => "/legacy"

  # New Rails routes
  resources :games do
    member do
      post 'start'
      post 'ask_tricks'
      post 'register_tricks'
      get 'show'
      get 'leaderboard'
      get 'winners'
    end
  end

  # API routes
  namespace :api do
    resources :games, only: [:create, :show, :update] do
      member do
        get 'leaderboard'
        post 'update_game_state', to: 'games#update_state'
      end
    end
  end

  # Set the root to the games index
  root "games#index"
end
