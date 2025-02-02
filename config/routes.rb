Rails.application.routes.draw do
  root 'home#index'
  get "up" => "rails/health#show", as: :rails_health_check

  get '/auth/install', to: 'auth#install'
  get '/auth/callback', to: 'auth#callback'
  post 'webhooks/product_update', to: 'webhooks#product_update'

  resources :products, only: [] do
    collection do
      post :sync
    end
  end
end
