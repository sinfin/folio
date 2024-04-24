# frozen_string_literal: true

class Folio::Users::SessionsController < Devise::SessionsController
  include Folio::Users::DeviseControllerBase

  protect_from_forgery prepend: true

  def destroy
    if current_user
      if Rails.application.config.folio_crossdomain_devise || Rails.application.config.folio_users_sign_out_everywhere
        current_user.sign_out_everywhere!
      end
    end

    super
  end

  def create
    if Rails.application.config.folio_users_publicly_invitable &&
       params[:user] &&
       params[:user][:email].present? &&
       email_belongs_to_invited_pending_user?(params[:user][:email])
      controller = self.class.to_s.gsub("Sessions", "Invitations").constantize.new
      controller.request = request
      controller.response = response
      render plain: controller.process("create")
    else
      respond_to do |format|
        format.html do
          warden_exception_or_user = catch :warden do
            self.resource = warden.authenticate!(auth_options)
          end

          if resource
            set_flash_message!(:notice, :signed_in)

            sign_in(resource_name, resource)

            yield resource if block_given?
            respond_with resource, location: after_sign_in_path_for(resource)
          else
            message = get_failure_flash_message(warden_exception_or_user)
            redirect_to main_app.new_user_session_path, flash: { alert: message }
          end
        end

        format.json do
          if request.referrer
            if params[:modal_non_get_request].blank?
              store_location_for(:user, request.referrer)
            elsif path = Rails.application.config.folio_users_non_get_referrer_rewrite_proc.call(request.referrer)
              store_location_for(:user, path)
            else
              store_location_for(:user, main_app.send(Rails.application.config.folio_users_after_sign_in_path))
            end
          else
            store_location_for(:user, main_app.send(Rails.application.config.folio_users_after_sign_in_path))
          end

          warden_exception_or_user = catch :warden do
            self.resource = warden.authenticate(auth_options)
          end

          if resource
            sign_in(resource_name, resource)

            @force_flash = true
            set_flash_message!(:notice, :signed_in)
            render json: { data: { url: after_sign_in_path_for(resource) } }, status: 200
          else
            message = get_failure_flash_message(warden_exception_or_user)

            errors = [{ status: 401, title: "Unauthorized", detail: message }]
            cell_flash = ActionDispatch::Flash::FlashHash.new
            cell_flash[:alert] = message

            html = cell("folio/devise/sessions/new",
                        resource: resource || Folio::User.new(email: params[:user][:email]),
                        resource_name: :user,
                        modal: true,
                        flash: cell_flash,
                        modal_non_get_request: params[:modal_non_get_request].present?).show

            render json: { errors:, data: html }, status: 401
          end
        end
      end
    end
  end

  def get_failure_flash_message(warden_exception_or_user)
    if warden_exception_or_user.is_a?(Hash)
      if warden_exception_or_user[:message].nil?
        I18n.t("folio.devise.sessions.create.invalid")
      elsif warden_exception_or_user[:message] == :unconfirmed
        unconfirmed_flash_message
      else
        I18n.t("devise.failure.#{warden_exception_or_user[:message]}", default: unconfirmed_flash_message)
      end
    else
      I18n.t("devise.failure.invalid", authentication_keys: resource_class.authentication_keys.join(", "))
    end
  end

  def unconfirmed_flash_message
    link = ActionController::Base.helpers.link_to(I18n.t("folio.devise.confirmations.new.header"),
                                                  main_app.new_user_confirmation_path(email: params[:user] && params[:user][:email]))

    msg = I18n.t("devise.failure.unconfirmed")

    "#{msg} #{link}"
  end

  def require_no_authentication
    safe_set_up_current_from_request

    result = handle_crossdomain_devise

    if result && result.action == :noop
      if current_user && !request.format.json?
        set_flash_message!(:notice, :signed_in)
        redirect_to after_sign_in_path_for(current_user)
      else
        super
      end
    end
  end
end
