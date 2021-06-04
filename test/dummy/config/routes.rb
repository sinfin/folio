# frozen_string_literal: true

Rails.application.routes.draw do
  root to: "home#index"

  mount Folio::Engine => "/"

  if Rails.application.config.folio_users
    devise_for :accounts, class_name: "Folio::Account", module: "folio/accounts"
    devise_for :users, class_name: "Folio::User",
                       module: "dummy/folio/users",
                       omniauth_providers: Rails.application.config.folio_users_omniauth_providers
  end

  resource :test, only: [:show]
  get "/dropzone", to: "home#dropzone"
  get "/lead_form", to: "home#lead_form"
  get "/gallery", to: "home#gallery"

  get "/download/:hash_id/*name", to: "downloads#show",
                                  as: :download,
                                  constraints: { name: /.*/ }

  scope module: :dummy, as: :dummy do
    namespace :blog do
      resources :articles, only: %i[show] do
        member { get :preview }
      end

      get "/", to: "articles#index", as: :articles

      resources :topics, only: %i[show] do
        member { get :preview }
      end
    end
  end

  scope module: :folio do
    namespace :console do
      namespace :dummy do
        namespace :blog do
          resources :articles, except: %i[show]
          resources :topics, except: %i[show]
        end
      end
    end
  end

  if Rails.application.config.folio_pages_translations
    scope "/:locale", locale: /#{I18n.available_locales.join('|')}/ do
      if Rails.application.config.folio_pages_ancestry
        get "/*path", to: "pages#show", as: "page"
      else
        resources :pages, only: [:show], path: ""
      end
    end
  else
    if Rails.application.config.folio_pages_ancestry
      get "/*path", to: "pages#show", as: "page" do
        member { get :preview }
      end
    else
      resources :pages, only: [:show], path: "" do
        member { get :preview }
      end
    end
  end
end
