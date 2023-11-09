# frozen_string_literal: true

scope module: :dummy, as: :dummy do
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
end
