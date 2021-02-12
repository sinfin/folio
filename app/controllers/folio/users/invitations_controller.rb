# frozen_string_literal: true

class Folio::Users::InvitationsController < Devise::InvitationsController
  def new
    fail ActionController::MethodNotAllowed, ""
  end

  def create
    fail ActionController::MethodNotAllowed, ""
  end
end
