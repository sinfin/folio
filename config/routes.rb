# frozen_string_literal: true

Folio::Engine.routes.draw do
  get "errors/not_found"

  get "errors/internal_server_error"

  devise_for :accounts, class_name: "Folio::Account", module: "folio/accounts"

  root to: "home#index"

  namespace :console do
    root to: "dashboard#index"
    resources :dashboard, only: :index

    resources :pages, except: %i[show] do
      collection do
        post :set_positions
        get :merge
      end

      member do
        if Rails.application.config.folio_pages_audited
          get :revision, path: "revision/:version"
          post :restore, path: "restore/:version"
        end
      end
    end

    resource :content_templates, only: [] do
      get :index
      get :edit, path: ":type/edit"
      patch :update, path: ":type/update", as: :update
    end

    resources :menus, only: [:edit, :update, :index]

    resources :images, only: %i[index]
    resources :documents, only: %i[index]

    resources :leads, only: %i[index show edit update destroy] do
      collection { post :mass_handle }
      member { post :event }
    end
    resources :newsletter_subscriptions, only: %i[index destroy]
    resources :accounts
    resources :visits, only: %i[index show]
    resource :search, only: %i[show]
    resource :site, only: %i[edit update] do
      post :clear_cache
    end

    namespace :api do
      resource :tags, only: [] do
        get :react_select
      end

      resource :aasm, only: [], controller: "aasm" do
        post :event
      end

      resource :autocomplete, only: %i[show] do
        get :field
        get :selectize
        get :react_select
      end

      resources :file_placements, only: %i[index],
                                  path: "files/:file_id/file_placements"

      resources :images, only: %i[index create update destroy] do
        collection do
          post :tag
          delete :mass_destroy
          get :mass_download
        end
        member do
          post :update_file_thumbnail
          post :change_file
        end
      end
      resources :documents, only: %i[index create update destroy] do
        collection do
          post :tag
          delete :mass_destroy
          get :mass_download
        end
        member do
          post :change_file
        end
      end
    end

    resource :merge, only: [:new, :create],
                     path: "merge/:klass/:original_id/:duplicate_id"

    resources :atoms, only: [:index] do
      collection do
        get :placement_preview, path: "placement_preview/:klass/:id"
        post :preview
        post :validate
      end
    end
  end

  resource :csrf, only: %i[show], controller: :csrf
  resources :leads, only: %i[create]
  resources :newsletter_subscriptions, only: %i[create]

  scope "/:locale", locale: /#{I18n.available_locales.join('|')}/ do
    get "/download/:hash_id/*name", to: "downloads#show",
                                    as: :download,
                                    constraints: { name: /.*/ }
  end
end
