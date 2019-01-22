# frozen_string_literal: true

Folio::Engine.routes.draw do
  get 'errors/not_found'

  get 'errors/internal_server_error'

  devise_for :accounts, class_name: 'Folio::Account', module: :devise

  root to: 'home#index', as: :home

  namespace :console, locale: Rails.application.config.folio_console_locale do
    root to: 'dashboard#index'
    resources :dashboard, only: :index
    resources :nodes, except: %i[show] do
      post :set_positions, on: :collection
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
    resources :leads, only: %i[index show update destroy] do
      collection do
        post :mass_handle
      end
      member do
        post :handle
        post :unhandle
      end
    end
    resources :newsletter_subscriptions, only: %i[index destroy]
    resources :accounts
    resources :visits, only: %i[index show]
    resources :links, only: %i[index]
    resource :site
  end

  resource :csrf, only: %i[show], controller: :csrf
  resources :leads, only: %i[create]
  resources :newsletter_subscriptions, only: %i[create]
end
