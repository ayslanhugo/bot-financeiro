Rails.application.routes.draw do
  # Rotas para categorias e despesas
  resources :categories
  resources :expenses
  
  resources :users, only: [:update]

  # Autenticação
  devise_for :users
  
  # Rota inicial (Dashboard)
  root "expenses#index"
  
  # Rota do Bot do Telegram
  post 'telegram/webhook', to: 'telegram#webhook'
  
  # Health check do Rails
  get "up" => "rails/health#show", as: :rails_health_check
end