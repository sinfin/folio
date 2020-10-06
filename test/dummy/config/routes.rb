# frozen_string_literal: true

Rails.application.routes.draw do
  root to: "home#index"

  mount Folio::Engine => "/"

  resource :test, only: [:show]
  get "/dropzone", to: "home#dropzone"
  get "/lead_form", to: "home#lead_form"

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
