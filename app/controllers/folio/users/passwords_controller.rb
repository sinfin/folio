# frozen_string_literal: true

class Folio::Users::PasswordsController < Devise::PasswordsController
  include Folio::Users::DeviseControllerBase
end
