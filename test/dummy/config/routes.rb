# frozen_string_literal: true

Rails.application.routes.draw do
  root to: "dummy/home#index"

  mount Folio::Engine => "/"

  if Rails.application.config.folio_users
    devise_for :accounts, class_name: "Folio::Account", module: "folio/accounts"
    devise_for :users, class_name: "Folio::User",
                       module: "dummy/folio/users",
                       omniauth_providers: Rails.application.config.folio_users_omniauth_providers

    devise_scope :user do
      get "/users/registrations/edit_password", to: "dummy/folio/users/registrations#edit_password"
      patch "/users/registrations/update_password", to: "dummy/folio/users/registrations#update_password"
      get "/users/invitation", to: "dummy/folio/users/invitations#show", as: nil
      get "/users/auth/conflict", to: "dummy/folio/users/omniauth_callbacks#conflict"
      get "/users/auth/resolve_conflict", to: "dummy/folio/users/omniauth_callbacks#resolve_conflict"
      get "/users/auth/new_user", to: "dummy/folio/users/omniauth_callbacks#new_user"
      post "/users/auth/create_user", to: "dummy/folio/users/omniauth_callbacks#create_user"
    end
  end

  resource :test, only: [:show]
  get "/dropzone", to: "home#dropzone"
  get "/lead_form", to: "home#lead_form"
  get "/gallery", to: "home#gallery"

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

  scope module: :dummy, as: :dummy do
    resource :search, only: %i[show] do
      get :autocomplete
      get :pages
    end

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

  if Rails.application.config.folio_pages_locales
    scope "/:locale", locale: /#{I18n.available_locales.join('|')}/ do
      if Rails.application.config.folio_pages_ancestry
        get "/*path", to: "dummy/pages#show", as: "page"
      else
        resources :pages, controller: "dummy/pages", only: [:show], path: ""
      end
    end
  else
    if Rails.application.config.folio_pages_ancestry
      get "/*path", to: "dummy/pages#show", as: "page"
    else
      resources :pages, controller: "dummy/pages", only: [:show], path: ""
    end
  end
end
