# frozen_string_literal: true

class Folio::Accounts::SessionsController < Devise::SessionsController
  include Folio::Accounts::DeviseControllerBase

  def destroy
    current_account.sign_out_everywhere! if Rails.application.config.folio_crossdomain_devise && current_account
    super
  end
end
