# frozen_string_literal: true

Folio::Engine.routes.draw do
  get "errors/not_found"

  get "errors/internal_server_error"

  unless Rails.application.config.folio_users
    devise_for :accounts, class_name: "Folio::Account", module: "folio/accounts"
  end

  namespace :devise do
    namespace :omniauth do
      resource :authentication, only: %i[destroy]
    end
  end

  namespace :users do
    get "/comeback", to: "comebacks#show"
  end

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

    resources :menus, except: %i[show]

    resources :images, only: %i[index]
    resources :documents, only: %i[index]

    resources :leads, only: %i[index show edit update destroy] do
      collection { post :mass_handle }
      member { post :event }
    end
    resources :newsletter_subscriptions, only: %i[index destroy]

    resources :accounts, except: %i[show] do
      member { post :invite_and_copy }
    end

    resources :email_templates, only: %i[index edit update]
    resource :search, only: %i[show]
    resource :site, only: %i[edit update] do
      post :clear_cache
    end

    resources :users do
      member do
        get :send_reset_password_email
        get :impersonate
      end

      collection do
        delete :collection_destroy
        get :collection_csv
      end
    end

    resource :transport, only: [] do
      get :out, path: "out/:class_name/:id"
      get :download, path: "download/:class_name/:id"

      get :in, path: "in(/:class_name/:id)"
      post :transport, path: "transport(/:class_name/:id)"
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
        get :select2
        get :react_select
      end

      resources :private_attachments, only: %i[create destroy]

      resources :file_placements, only: %i[index],
                                  path: "files/:file_id/file_placements"

      resources :links, only: %i[index]

      resources :console_notes, only: [] do
        member do
          post :toggle_closed_at
        end

        collection do
          post :react_update_target
        end
      end

      resources :images, only: %i[index update destroy] do
        collection do
          post :tag
          delete :mass_destroy
          get :mass_download
        end
        member do
          post :update_file_thumbnail
          post :destroy_file_thumbnail
          post :change_file
        end
      end

      resources :documents, only: %i[index update destroy] do
        collection do
          post :tag
          delete :mass_destroy
          get :mass_download
        end
        member do
          post :change_file
        end
      end

      resource :s3_signer, only: [], controller: "s3_signer" do
        post :s3_before
        post :s3_after
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
  resources :session_attachments, only: %i[create index destroy],
                                  as: :folio_session_attachments

  get "/folio/ui", to: "ui#ui"
  get "/folio/ui/mobile_typo", to: "ui#mobile_typo"
  get "/folio/ui/atoms", to: "ui#atoms"

  get "/download/:hash_id(/*name)", to: "downloads#show",
                                    as: :download,
                                    constraints: { name: /.*/ }

  get "/sitemaps/:id.:format(.:compression)", to: "sitemaps#show"

  require "sidekiq/web"
  require "sidekiq/cron/web"

  authenticate :account, lambda { |account| account.can_manage_sidekiq? } do
    mount Sidekiq::Web => "/sidekiq"
  end
end
