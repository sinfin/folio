# frozen_string_literal: true

class Folio::Users::InvitationsController < Devise::InvitationsController
  include Folio::Users::DeviseControllerBase

  def show
    if session[:folio_user_invited_email]
      @email = session[:folio_user_invited_email]
    else
      redirect_to new_user_invitation_path
    end
  end

  def after_invite_path_for(_inviter, resource)
    session[:folio_user_invited_email] = resource.email
    user_invitation_path
  end
end
