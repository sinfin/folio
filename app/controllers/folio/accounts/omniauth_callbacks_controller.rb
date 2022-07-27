# frozen_string_literal: true

class Folio::Accounts::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Folio::Accounts::DeviseControllerBase
end
