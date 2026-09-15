# frozen_string_literal: true

module Folio::Users::DeviseControllerBase
  extend ActiveSupport::Concern
  include Folio::Devise::CrossdomainController

  included do
    before_action :add_auth_site_id_to_params
    rescue_from "Folio::Devise::EmailLogin::Pending", with: :render_email_login_pending
    rescue_from "Folio::Devise::EmailLogin::Throttled", with: :render_email_login_throttled
    rescue_from "Folio::Devise::EmailLogin::InvalidChallenge", with: :render_email_login_invalid
  end

  def after_sign_in_path_for(_resource)
    stored_location_for(:user) ||
    main_app.send(Rails.application.config.folio_users_after_sign_in_path)
  end

  def after_sign_out_path_for(_resource)
    main_app.send(Rails.application.config.folio_users_after_sign_out_path)
  end

  def after_sign_up_path_for(_resource)
    stored_location_for(:user) ||
    main_app.send(Rails.application.config.folio_users_after_sign_up_path)
  end

  def after_accept_path_for(_resource)
    stored_location_for(:user) ||
    main_app.send(Rails.application.config.folio_users_after_accept_path)
  end

  def signed_in_root_path(_resource)
    main_app.send(Rails.application.config.folio_users_signed_in_root_path)
  end

  def set_flash_message(key, kind, options = {})
    if key == :notice
      super(:success, kind, options)
    else
      super(key, kind, options)
    end
  end

  def is_flashing_format?
    if @force_flash
      true
    else
      super
    end
  end

  def sign_in(resource_or_scope, *args)
    candidate = resource_or_scope.is_a?(Symbol) ? args.first : resource_or_scope
    if Folio::Devise::EmailLogin.verification_enabled? && candidate.is_a?(Folio::User) && warden.user(:user) != candidate
      purpose = { "omniauth_callbacks" => "oauth", "passwords" => "password_reset", "invitations" => "invitation" }.fetch(controller_name, "registration")
      Folio::Devise::EmailLogin::Gate.check!(candidate, request:, purpose:, remember_me: candidate.remember_me)
    end

    super

    set_resource(resource_or_scope, args&.first) if resource.nil?
    if Folio::Devise::EmailLogin.enabled? && resource.is_a?(Folio::User)
      Folio::Current.user = resource
      Folio::Current.reset_ability!
    end
    acquire_orphan_records!
    create_site_user_link
    after_sign_in
  end

  def after_sign_in
    # eg: in case of invalid resource set store_location_for() to resource edit
  end

  def email_belongs_to_invited_pending_user?(email)
    user = Folio::User.find_by(email:)
    user && user.invitation_created_at? && user.invitation_accepted_at.nil? && user.sign_in_count == 0
  end

  private
    def render_email_login_pending
      if request.format.json?
        render json: { data: { url: main_app.user_email_login_path } }
      else
        redirect_to main_app.user_email_login_path
      end
    end

    def render_email_login_throttled(error = nil)
      retry_after = email_login_retry_after(error)
      response.set_header("Retry-After", retry_after.to_s)
      if request.format.json?
        render json: { error: I18n.t("folio.users.email_login.throttled") }, status: :too_many_requests
      else
        render plain: I18n.t("folio.users.email_login.throttled"), status: :too_many_requests
      end
    end

    def email_login_retry_after(error = nil)
      error&.retry_after || request.env["folio.email_login.retry_after"] || Folio::Devise::EmailLogin::RESEND_INTERVAL.to_i
    end

    def render_email_login_invalid
      if request.format.json?
        render json: { error: I18n.t("folio.users.email_login.invalid") }, status: :unprocessable_entity
      else
        redirect_to main_app.new_user_session_path, alert: I18n.t("folio.users.email_login.invalid")
      end
    end

    def add_auth_site_id_to_params
      if request.params["user"]
        request.params["user"]["auth_site_id"] = (::Folio::Current.enabled_site_for_crossdomain_devise || Folio::Current.site).id.to_s
      end
    end

    def safe_set_up_current_from_request
      if respond_to?(:set_up_current_from_request, true)
        set_up_current_from_request
      end
    end

  protected
    # override devise signed in check - redirect to source site if needed
    def require_no_authentication
      safe_set_up_current_from_request
      result = handle_crossdomain_devise
      super if result && result.action == :noop
    end

    def acquire_orphan_records!
      if resource && session && session.id && session.id.public_id
        resource.acquire_orphan_records!(old_session_id: session.id.public_id)
      end
    end

    def create_site_user_link
      if resource&.respond_to?(:site_user_links)
        resource.create_site_links_for([Folio::Current.site])
      end
    end

    def set_resource(resource_or_scope, resource_passed = nil)
      if resource_passed.blank?
        resource_passed = resource_or_scope unless resource_or_scope.is_a?(Symbol)
      end
      instance_variable_set(:"@#{resource_name}", resource_passed)
    end
end
