# frozen_string_literal: true

begin
  Folio::Engine.routes.default_url_options[:host] = Folio::Site.first.url if ActiveRecord::Base.connection.table_exists? 'folio_sites'
rescue NoMethodError

end

Folio::Engine.routes.draw do
  get 'errors/not_found'

  get 'errors/internal_server_error'

  devise_for :accounts, class_name: 'Folio::Account', module: :devise

  root to: 'home#index', as: :home

  match '/404', to: 'errors#page404', via: :all
  match '/422', to: 'errors#page422', via: :all
  match '/500', to: 'errors#page500', via: :all

  namespace :console do
    root to: 'nodes#index'
    resources :dashboard, only: :index
    resources :nodes, except: [:show] do
      post 'set_position', on: :collection
    end
    resources :menus, except: [:show]
    resources :files, except: [:show]
    resources :leads, only: %i[index edit update destroy]
    resources :newsletter_subscriptions, only: %i[index destroy]
    resources :accounts
    resources :sites
    resources :visits, only: %i[index show]
  end

  scope '/:locale', locale: /#{I18n.available_locales.join('|')}/ do
    resources :categories, only: %i[index show]
    # resources :pages, only: %i[index show]
    resources :leads, only: %i[create]
    resources :newsletter_subscriptions, only: %i[create]

    get '/*path', to: 'pages#show', as: 'page'
  end

end
