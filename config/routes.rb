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

    scope constraints: Rails.application.config.folio_console_default_routes_contstraints do
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

      namespace :file do
        Rails.application.config.folio_file_types_for_routes.each do |type|
          resources type.constantize.model_name.element.pluralize.to_sym, only: %i[index show]
        end
      end

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
        resources :private_attachments, only: %i[create destroy]

        resources :links, only: %i[index]

        resource :current_account, only: [] do
          post :console_path_ping
        end

        resources :console_notes, only: [] do
          member do
            post :toggle_closed_at
          end

          collection do
            post :react_update_target
          end
        end

        namespace :file do
          Rails.application.config.folio_file_types_for_routes.each do |type|
            klass = type.constantize
            key = type.constantize.model_name.element.pluralize.to_sym

            resources key, only: %i[index update destroy] do
              collection do
                post :tag
                delete :mass_destroy
                get :mass_download
              end
              member do
                if klass.human_type == "image"
                  post :update_file_thumbnail
                  post :destroy_file_thumbnail
                end
              end
            end
          end
        end
      end

      resource :merge, only: [:new, :create],
                       path: "merge/:klass/:original_id/:duplicate_id"
    end

    # these are outside of constraint by design
    namespace :api do
      resource :aasm, only: [], controller: "aasm" do
        post :event
      end

      resource :jw_player, only: [], controller: "jw_player" do
        get :video_url
      end

      resources :tags, only: %i[index]

      resource :autocomplete, only: %i[show] do
        get :field
        get :selectize
        get :select2
        get :react_select
      end

      resources :file_placements, only: %i[index],
                                  path: "files/:file_id/file_placements"
    end

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

  scope :folio, as: :folio do
    namespace :api do
      resource :s3, only: [], controller: "s3" do
        post :before
        post :after
        post :multipart_before
        post :multipart_after
      end

      resource :ares, only: [], controller: "ares" do
        post :subject
      end
    end
  end

  get "/folio/ui", to: "ui#ui"
  get "/folio/ui/mobile_typo", to: "ui#mobile_typo"
  get "/folio/ui/atoms", to: "ui#atoms"

  get "/download/:hash_id(/*name)", to: "downloads#show",
                                    as: :download,
                                    constraints: { name: /.*/ }

  unless Rails.application.config.folio_site_is_a_singleton
    get "/robots.txt" => "robots#index"
  end

  get "/sitemaps/:id.:format(.:compression)", to: "sitemaps#show"

  require "sidekiq/web"
  require "sidekiq/cron/web"

  authenticate :account, lambda { |account| account.can_manage_sidekiq? } do
    mount Sidekiq::Web => "/sidekiq"
  end
end
