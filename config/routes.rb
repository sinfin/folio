# frozen_string_literal: true

Folio::Engine.routes.default_url_options[:host] = Folio::Site.first.url

Folio::Engine.routes.draw do
  get 'errors/not_found'

  get 'errors/internal_server_error'

  devise_for :accounts, class_name: 'Folio::Account', module: :devise

  root to: 'home#index', as: :home

  resources :categories, only: %i[index show]
  resources :pages, only: %i[index show]

  match '/404', to: 'errors#not_found', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all

  namespace :console do
    root to: 'nodes#index'
    resources :dashboard, only: :index
    resources :nodes
    resources :files, except: [:show]
    resources :accounts
    resources :sites
  end
end
