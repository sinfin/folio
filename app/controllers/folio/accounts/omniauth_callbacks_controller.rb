# frozen_string_literal: true

class Folio::Accounts::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  layout "folio/console/devise"
end
