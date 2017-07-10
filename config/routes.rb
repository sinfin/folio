Folio::Engine.routes.draw do
  devise_for :accounts, class_name: "Folio::Account", module: :devise

  root to: 'home#index', as: :home

  resources :categories, only: [ :index, :show ]
  resources :pages, only: [ :index, :show ]

  namespace :console do
    root to: 'dashboard#index'
    resource :dashboard
  end
end
