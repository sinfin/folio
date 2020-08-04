# frozen_string_literal: true

Rails.application.routes.draw do
  root to: 'home#index'

  mount Folio::Engine => '/'

  get '/400', to: 'errors#page400', via: :all
  get '/404', to: 'errors#page404', via: :all
  get '/422', to: 'errors#page422', via: :all
  get '/500', to: 'errors#page500', via: :all

  scope '/:locale', locale: /#{I18n.available_locales.join('|')}/ do
    resources :pages, only: [:show], path: '' do
      member { get :preview }
    end
  end

  require 'sidekiq/web'
  authenticate :account do
    mount Sidekiq::Web => '/sidekiq'
  end
end
