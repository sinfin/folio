Folio::Engine.routes.draw do

  root to: 'home#index', as: :home
  resources :categories, only: [ :index, :show ]
  resources :pages, only: [ :index, :show ]

end
