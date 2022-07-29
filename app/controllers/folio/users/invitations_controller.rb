# frozen_string_literal: true

class Folio::Users::InvitationsController < Devise::InvitationsController
  include Folio::Users::DeviseControllerBase

  before_action :disallow_public_invitations_if_needed, only: %i[create new]

  def show
    if session[:folio_user_invited_email]
      @email = session[:folio_user_invited_email]
    else
      redirect_to new_user_invitation_path
    end
  end

  def create
    self.resource = invite_resource
    resource_invited = resource.errors.empty?

    respond_to do |format|
      # need to override devise invitable here with devise default
      format.html do
        yield resource if block_given?

        if resource_invited
          if is_flashing_format? && self.resource.invitation_sent_at
            set_flash_message :notice, :send_instructions, email: self.resource.email
          end
          if self.method(:after_invite_path_for).arity == 1
            respond_with resource, location: after_invite_path_for(current_inviter)
          else
            respond_with resource, location: after_invite_path_for(current_inviter, resource)
          end
        else
          respond_with_navigational(resource) { render :new, status: :unprocessable_entity }
        end
      end
      # custom fro JSON api
      format.json do
        @force_flash = true

        if resource_invited
          if is_flashing_format? && self.resource.invitation_sent_at
            set_flash_message :notice, :send_instructions, email: self.resource.email
          end

          if Rails.application.config.folio_users_after_ajax_sign_up_redirect
            json = {
              data: {
                url: stored_location_for(:user).presence || after_invite_path_for(current_inviter, resource),
              }
            }
          else
            json = {
              data: {
                url: after_invite_path_for(current_inviter, resource),
              }
            }
          end

          render json:, status: 200
        else
          message = t("folio.users.invitations.create.failure")

          errors = [{ status: 401, title: "Unauthorized", detail: message }]
          cell_flash = ActionDispatch::Flash::FlashHash.new
          cell_flash[:alert] = message

          html = cell("folio/devise/invitations/new",
                      resource:,
                      resource_name: :user,
                      modal: true,
                      flash: cell_flash).show

          render json: { errors:, data: html }, status: 401
        end
      end
    end
  end

  def after_invite_path_for(_inviter, resource)
    session[:folio_user_invited_email] = resource.email
    user_invitation_path
  end

  def is_flashing_format?
    if @force_flash
      true
    else
      super
    end
  end

  private
    def update_resource_params
      params.require(:user).permit(*Folio::User.controller_strong_params_for_create).to_h.merge(super)
    end

    def disallow_public_invitations_if_needed
      return if Rails.application.config.folio_users_publicly_invitable
      fail "Not allowed to publicly invite."
    end
end
