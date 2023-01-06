# frozen_string_literal: true

class Folio::Users::SessionsController < Devise::SessionsController
  include Folio::Users::DeviseControllerBase

  protect_from_forgery prepend: true

  def destroy
    current_user.sign_out_everywhere! if Rails.application.config.folio_crossdomain_devise && current_user
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
          warden_exception_or_user = catch :warden do
            self.resource = warden.authenticate(auth_options)
          end

          if resource
            sign_in(resource_name, resource)
            @force_flash = true
            set_flash_message!(:notice, :signed_in)
            render json: {}, status: 200
          else
            message = get_failure_flash_message(warden_exception_or_user)

            errors = [{ status: 401, title: "Unauthorized", detail: message }]
            cell_flash = ActionDispatch::Flash::FlashHash.new
            cell_flash[:alert] = message

            html = cell("folio/devise/sessions/new",
                        resource: resource || Folio::User.new(email: params[:user][:email]),
                        resource_name: :user,
                        modal: true,
                        flash: cell_flash).show

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

  def email_belongs_to_invited_pending_user?(email)
    user = Folio::User.find_by(email:)
    user.invitation_created_at? && user.invitation_accepted_at.nil? && user.sign_in_count == 0
  end
end
