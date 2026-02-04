Rails.application.routes.draw do
  devise_for :users

  resource :profile, only: [:show, :edit, :update], controller: 'users'

  resources :expenses
  
  root "expenses#index"
  
  post 'telegram/webhook', to: 'telegram#webhook'
  
  # Health check padrão do Rails
  get "up" => "rails/health#show", as: :rails_health_check
end