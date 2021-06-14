# frozen_string_literal: true

class Folio::Users::ConfirmationsController < Devise::ConfirmationsController
  include Folio::Users::DeviseControllerBase

  def new
    super
    self.resource.email ||= params[:email]
  end
end
