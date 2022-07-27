# frozen_string_literal: true

class Folio::Accounts::ConfirmationsController < Devise::ConfirmationsController
  include Folio::Accounts::DeviseControllerBase

  def new
    super
    resource.email ||= params[:email]
  end
end
