# frozen_string_literal: true

class Folio::Users::InvitationsController < Devise::InvitationsController
  include Folio::Users::DeviseUserPaths

  def new
    fail ActionController::MethodNotAllowed, ""
  end

  def create
    fail ActionController::MethodNotAllowed, ""
  end
end
