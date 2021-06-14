# frozen_string_literal: true

class Folio::Accounts::ConfirmationsController < Devise::ConfirmationsController
  layout "folio/console/devise"

  def new
    super
    resource.email ||= params[:email]
  end
end
