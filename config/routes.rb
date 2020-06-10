# frozen_string_literal: true

Folio::Engine.routes.draw do
  get 'errors/not_found'

  get 'errors/internal_server_error'

  devise_for :accounts, class_name: 'Folio::Account', module: 'folio/accounts'

  root to: 'home#index'

  namespace :console do
    root to: 'dashboard#index'
    resources :dashboard, only: :index

    resources :pages, except: %i[show] do
      post :set_positions, on: :collection
    end

    resources :menus do
      post :tree_sort, on: :member
    end

    resources :images, only: %i[index edit update destroy]
    resources :documents, only: %i[index edit update destroy]

    resources :leads, only: %i[index show edit update destroy] do
      collection { post :mass_handle }
      member { post :event }
    end
    resources :newsletter_subscriptions, only: %i[index destroy]
    resources :accounts
    resources :visits, only: %i[index show]
    resource :search, only: %i[show]
    resource :site, only: %i[edit update]

    namespace :api do
      resources :links, only: %i[index]
      resources :images, only: %i[index create update] do
        collection { post :tag }
      end
      resources :documents, only: %i[index create update] do
        collection { post :tag }
      end
    end
  end

  resource :csrf, only: %i[show], controller: :csrf
  resources :leads, only: %i[create]
  resources :newsletter_subscriptions, only: %i[create]

  def self.locale_scope_if_enabled
    if Rails.application.config.folio_routes_localized
      scope '/:locale', locale: /#{I18n.available_locales.join('|')}/ do
        yield
      end
    else
      yield
    end
  end

  locale_scope_if_enabled do
    get '/download/:hash_id/*name', to: 'downloads#show',
                                    as: :download,
                                    constraints: { name: /.*/ }
  end
end
