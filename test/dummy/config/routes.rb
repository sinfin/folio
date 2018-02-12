# frozen_string_literal: true

Rails.application.routes.draw do
  root to: 'home#index'

  mount Folio::Engine => '/'

  scope '/:locale', locale: /#{I18n.available_locales.join('|')}/ do
    get '/*path', to: 'pages#show', as: 'page'
  end
end
