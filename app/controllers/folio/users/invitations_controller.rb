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

  private
    def update_resource_params
      params.require(:user).permit(*additional_user_params).to_h.merge(super)
    end

    def additional_user_params
      [
        :first_name,
        :last_name,
        :nickname,
        :phone,
        :subscribed_to_newsletter,
        :use_secondary_address,
        primary_address_attributes: address_strong_params,
        secondary_address_attributes: address_strong_params,
      ]
    end

    def address_strong_params
      %i[
        id
        _destroy
        name
        company_name
        address_line_1
        address_line_2
        zip
        city
        country_code
        phone
      ]
    end
end
