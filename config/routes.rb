# frozen_string_literal: true

Folio::Engine.routes.draw do
  get 'errors/not_found'

  get 'errors/internal_server_error'

  devise_for :accounts, class_name: 'Folio::Account', module: 'folio/accounts'

  root to: 'home#index', as: :home

  namespace :console, locale: Rails.application.config.folio_console_locale do
    root to: 'dashboard#index'
    resources :dashboard, only: :index

    resources :pages, except: %i[show] do
      post :set_positions, on: :collection
      resources :versions, only: :index, defaults: { item_class: 'Folio::Page' }
    end

    resources :menus do
      post :tree_sort, on: :member
    end
    resources :images, except: %i[show new] do
      collection { post :tag }
    end
    resources :documents, except: %i[show new] do
      collection { post :tag }
    end
    resources :leads, only: %i[index show edit update destroy] do
      collection { post :mass_handle }
      member { post :event }
    end
    resources :newsletter_subscriptions, only: %i[index destroy]
    resources :accounts
    resources :visits, only: %i[index show]
    resources :links, only: %i[index]
    resource :search, only: %i[show]
    resource :site, only: %i[edit update]
  end

  resource :csrf, only: %i[show], controller: :csrf
  resources :leads, only: %i[create]
  resources :newsletter_subscriptions, only: %i[create]
end
