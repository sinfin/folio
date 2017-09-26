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

  resources :categories, only: %i[index show]
  resources :pages, only: %i[index show]
  resources :leads, only: %i[create]

  match '/404', to: 'errors#page404', via: :all
  match '/422', to: 'errors#page422', via: :all
  match '/500', to: 'errors#page500', via: :all

  namespace :console do
    root to: 'nodes#index'
    resources :dashboard, only: :index
    resources :nodes, except: [:show]
    resources :menus, except: [:show]
    resources :files, except: [:show]
    resources :accounts
    resources :sites
  end
end
