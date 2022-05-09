# frozen_string_literal: true

class Folio::Accounts::PasswordsController < Devise::PasswordsController
  include Folio::Accounts::DeviseControllerBase
end
