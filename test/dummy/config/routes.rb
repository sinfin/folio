# frozen_string_literal: true

Rails.application.routes.draw do
  root to: "dummy/home#index"

  mount Folio::Engine => "/"

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

  resource :test, only: [:show]

  scope module: :folio do
    namespace :console do
      namespace :dummy do
        resource :playground, only: %i[] do
          get :private_attachments
          patch :update_private_attachments
          get :players
          get :pickers
          get :report
          get :modals
          get :multiselect
          get :console_notes
          patch :update_console_notes
        end

        namespace :blog do
          resources :articles, except: %i[show]
          resources :topics, except: %i[show] do
            post :set_positions, on: :collection
          end
        end
      end
    end
  end

  draw "dummy/ui"

  scope module: :dummy, as: :dummy do
    resource :atoms, only: %i[show]
    resource :ui, only: %i[show], controller: "ui" do
      get :alerts
      get :boolean_toggles
      get :buttons
      get :forms
      get :icons
      get :images
      get :modals
      get :pagination
      get :typo
    end

    scope module: :home do
      get :dropzone
      get :lead_form
      get :gallery
    end

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
