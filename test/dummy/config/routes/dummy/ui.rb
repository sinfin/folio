# frozen_string_literal: true

scope module: :dummy, as: :dummy do
  resource :ui, only: %i[show], controller: "ui" do
    get :alerts
    get :author_medallions
    get :boolean_toggles
    get :breadcrumbs
    get :buttons
    get :cards
    get :chips
    get :clipboard
    get :documents
    get :embed
    get :forms
    get :hero
    get :icons
    get :images
    get :inputs
    get :modals
    get :pagination
    get :share
    get :slide_lists
    get :tabs
    get :topics
    get :typo
  end
end
