# frozen_string_literal: true

class Folio::Accounts::RegistrationsController < Devise::RegistrationsController
  include Folio::Accounts::DeviseControllerBase
end
