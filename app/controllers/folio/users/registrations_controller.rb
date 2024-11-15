# frozen_string_literal: true

class Folio::Users::RegistrationsController < Devise::RegistrationsController
  prepend_before_action :authenticate_scope!, only: [:edit_password, :update_password]

  include Folio::Users::DeviseControllerBase

  def new
    fail ActionController::MethodNotAllowed, "Registrations are created by inviting user, not directly"
  end

  def edit
    if params[:pw]
      resource.send_reset_password_instructions
      redirect_back fallback_location: root_path,
                    flash: { success: t("folio.devise.registrations.edit.sent_reset_password_instructions") }
    else
      super
    end
  end

  def create
    fail ActionController::MethodNotAllowed, "Registrations are created by inviting user, not directly"

    build_resource(sign_up_params)

    resource.save

    respond_to do |format|
      format.html do
        # need to override devise invitable here with devise default

        yield resource if block_given?

        if resource.persisted?
          if resource.active_for_authentication?
            set_flash_message! :notice, :signed_up
            sign_up(resource_name, resource)
            respond_with resource, location: after_sign_up_path_for(resource)
          else
            set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
            expire_data_after_sign_in!
            respond_with resource, location: after_inactive_sign_up_path_for(resource)
          end
        else
          clean_up_passwords resource
          set_minimum_password_length
          respond_with resource
        end
      end

      format.json do
        if resource.persisted?
          @force_flash = true

          if resource.active_for_authentication?
            set_flash_message! :notice, :signed_up
            sign_up(resource_name, resource)
          else
            set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
            expire_data_after_sign_in!
          end

          if Rails.application.config.folio_users_after_ajax_sign_up_redirect
            json = {
              data: {
                url: stored_location_for(:user).presence || after_sign_up_path_for(resource),
              }
            }
          else
            json = {}
          end

          render json:, status: 200
        else
          clean_up_passwords resource
          set_minimum_password_length

          message = t("folio.users.registrations.create.failure")

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

  def edit_password
  end

  def update_password
    user = current_user

    if user.has_generated_password?
      update_password_params = params.require(:user)
                                     .permit(:password,
                                             :password_confirmation)

      success = user.update(update_password_params)
    else
      update_password_params = params.require(:user)
                                     .permit(:password,
                                             :password_confirmation,
                                             :current_password)

      success = user.update_with_password(update_password_params)
    end

    if success
      bypass_sign_in user
      redirect_to main_app.send(Rails.application.config.folio_users_after_password_change_path),
                  flash: { success: t("folio.devise.registrations.update_password.success") }
    else
      flash.now[:alert] = t("folio.devise.registrations.update_password.failure")
      render :edit_password
    end
  end

  def update_resource(resource, params)
    if resource.has_generated_password?
      # don't require current_password as the omniauth-user did not set one yet
      resource.update(params)
    elsif params[:email].present? || params[:current_password].present?
      # require current_password to update email
      super(resource, params)
    else
      # don't require current_password to update name etc.
      resource.update(params)
    end
  end

  private
    def sign_up_params
      params.require(:user).permit(*additional_user_params).to_h.merge(super)
    end

    def additional_user_params
      %i[first_name last_name nickname phone]
    end
end
