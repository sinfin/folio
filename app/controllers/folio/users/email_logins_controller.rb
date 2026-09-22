# frozen_string_literal: true

class Folio::Users::EmailLoginsController < DeviseController
  include Folio::Users::DeviseControllerBase
  include Folio::RenderComponentJson
  include Folio::Captcha::HasTurnstileValidation
  include Folio::Captcha::HasRecaptchaValidation

  protect_from_forgery with: :exception, prepend: true
  prepend_before_action :email_login_params, only: :create
  before_action :require_email_login_enabled
  before_action :private_email_login_response
  before_action :validate_recaptcha, only: :create
  before_action :authenticate_email_login_user, only: :revoke_trusted_browsers
  rescue_from "Folio::Devise::EmailLogin::InvalidChallenge", with: :invalid_email_login

  def new
    raise ActionController::RoutingError, "Not Found" unless Folio::Devise::EmailLogin.magic_link_enabled?

    capture_email_login_return_path
    render Folio::Users::EmailLogin::RequestComponent.new(user: Folio::User.new)
  end

  def create
    raise ActionController::RoutingError, "Not Found" unless Folio::Devise::EmailLogin.magic_link_enabled?

    email = email_login_params[:email]
    raise ActionController::BadRequest unless email.is_a?(String) && email.bytesize <= 320

    email = email.strip.downcase
    user = Folio::User.find_for_authentication(email:, auth_site_id: pending.site.id)
    invited_user = user if Rails.application.config.folio_users_publicly_invitable && user&.invited_to_sign_up?
    user = nil if user && (!user.active_for_authentication? || (user.respond_to?(:invited_to_sign_up?) && user.invited_to_sign_up?))
    pending.begin!(user:, purpose: "magic_link", email:,
                   remember_me: Devise::TRUE_VALUES.include?(email_login_params[:remember_me]))
    invited_user&.invite!
    render_email_login_pending
  end

  def show
    raise Folio::Devise::EmailLogin::InvalidChallenge if pending.data.empty?

    if completed_path
      redirect_to completed_path
    else
      render_waiting
    end
  end

  def status
    raise Folio::Devise::EmailLogin::InvalidChallenge if pending.data.empty?

    render json: { data: { state: pending.state, url: completed_path }.compact }
  end

  def confirm
    request.env["folio.skip_external_scripts"] = true
    @hide_share = true
    response.set_header("Content-Security-Policy", [response.headers["Content-Security-Policy"],
                                                   "script-src 'self' 'unsafe-inline'; connect-src 'self'; frame-src 'none'; object-src 'none'; base-uri 'self'"].compact.join(", "))
    return head(:ok) if request.head?
    return head(:unprocessable_entity) if request.query_parameters.key?("email_login_token")

    render Folio::Users::EmailLogin::ConfirmationComponent.new(preparing: true)
  end

  def prepare
    request.format = :json
    session.delete(Folio::Devise::EmailLogin::APPROVAL_SESSION_KEY) if params.key?(:email_login_token)
    # Proofs belong in the POST body; never accept them from query parameters.
    raise Folio::Devise::EmailLogin::InvalidChallenge if request.query_parameters.key?("email_login_token")

    if request.request_parameters.key?("email_login_token")
      token = request.request_parameters["email_login_token"]
      raise Folio::Devise::EmailLogin::InvalidChallenge unless token.is_a?(String) && token.match?(/\A[0-9a-f]{64}\z/)

      challenge = Folio::Users::EmailLoginChallenge.find_by(token_digest: Folio::Devise::EmailLogin.digest(token), site: pending.site)
      raise Folio::Devise::EmailLogin::InvalidChallenge unless challenge&.usable_for?(pending.site)

      session[Folio::Devise::EmailLogin::APPROVAL_SESSION_KEY] = { "id" => challenge.id, "email_login_token" => token }
    else
      challenge = approval_challenge
    end

    if Devise::TRUE_VALUES.include?(request.request_parameters["approve"])
      challenge.approve!(token: session[Folio::Devise::EmailLogin::APPROVAL_SESSION_KEY]["email_login_token"], site: pending.site)
      if pending.challenge&.id == challenge.id
        path = Folio::Devise::EmailLogin::CompleteLogin.call(self, trust_browser: pending.trust_browser)
        render json: { data: { url: path } }
      else
        render_component_json Folio::Users::EmailLogin::ConfirmationComponent.new(approved: true)
      end
    else
      render_component_json Folio::Users::EmailLogin::ConfirmationComponent.new(challenge:)
    end
  end

  def approve
    challenge = approval_challenge
    challenge.approve!(token: session[Folio::Devise::EmailLogin::APPROVAL_SESSION_KEY]["email_login_token"], site: pending.site)
    if pending.challenge&.id == challenge.id
      redirect_to main_app.user_email_login_path
    else
      render Folio::Users::EmailLogin::ConfirmationComponent.new(approved: true)
    end
  end

  def complete
    pending.trust_browser = Devise::TRUE_VALUES.include?(params[:trust_browser]) if params.key?(:trust_browser)
    if pending.state == "waiting"
      return render_email_login_pending
    end

    path = Folio::Devise::EmailLogin::CompleteLogin.call(self, trust_browser: pending.trust_browser)
    if request.format.json?
      render json: { data: { url: path } }
    else
      redirect_to path
    end
  end

  def resend
    pending.trust_browser = Devise::TRUE_VALUES.include?(params[:trust_browser]) if params.key?(:trust_browser)
    pending.resend!
    render_email_login_pending
  end

  def destroy
    pending.cancel!
    redirect_to main_app.new_user_session_path
  end

  def revoke_trusted_browsers
    current_user.revoke_email_login_verifications!
    Folio::Devise::EmailLogin::BrowserTrust.new(request:, user: current_user, site: pending.site).revoke!
    redirect_back fallback_location: main_app.users_registrations_edit_password_path, allow_other_host: false,
                  flash: { success: I18n.t("folio.users.email_login.revoked") }
  end

  private
    def render_waiting(status: :ok)
      render Folio::Users::EmailLogin::WaitingComponent.new(email: pending.data["email"], state: pending.state,
                                                          expires_at: pending.data["expires_at"],
                                                          resend_at: pending.resend_at.to_f,
                                                          trust_browser: pending.trust_browser), status:
    end

    def render_email_login_throttled(error = nil)
      return super if request.format.json? || pending.data.empty?

      retry_after = email_login_retry_after(error)
      pending.postpone_resend_until(retry_after.seconds.from_now)
      response.set_header("Retry-After", retry_after.to_s)
      flash.now[:alert] = I18n.t("folio.users.email_login.throttled")
      render_waiting(status: :too_many_requests)
    end

    def authenticate_email_login_user
      authenticate_user!(force: true)
    end

    def pending
      @pending ||= Folio::Devise::EmailLogin::RequestSession.new(request)
    end

    def completed_path
      challenge = pending.challenge
      if challenge&.consumed_at? && warden.user(:user)&.id == challenge.user_id
        session["folio.email_login_completed_path"]
      end
    end

    def approval_challenge
      data = session[Folio::Devise::EmailLogin::APPROVAL_SESSION_KEY] || {}
      if action_name == "approve" && params[:challenge_id].to_s != data["id"].to_s
        raise Folio::Devise::EmailLogin::InvalidChallenge
      end

      challenge = Folio::Users::EmailLoginChallenge.find_by(id: data["id"], site: pending.site)
      unless challenge&.token_matches?(data["email_login_token"]) && challenge.usable_for?(pending.site)
        raise Folio::Devise::EmailLogin::InvalidChallenge
      end
      challenge
    end

    def email_login_params
      value = params.require(:user)
      raise ActionController::BadRequest unless value.is_a?(ActionController::Parameters)

      value.permit(:email, :remember_me)
    end

    def capture_email_login_return_path
      path = Folio::Devise::EmailLogin.local_path(request.referrer, host: request.host)
      login_paths = [main_app.new_user_session_path, main_app.new_user_email_login_path].map { |route| URI.parse(route).path }
      return if path.nil? || URI.parse(path).path.in?(login_paths)

      if params[:modal_non_get_request].present?
        path = Rails.application.config.folio_users_non_get_referrer_rewrite_proc.call(path)
        path = Folio::Devise::EmailLogin.local_path(path, host: request.host)
      end
      store_location_for(:user, path) if path
    end

    def require_email_login_enabled
      raise ActionController::RoutingError, "Not Found" unless Folio::Devise::EmailLogin.enabled?
    end

    def private_email_login_response
      response.set_header("Cache-Control", "private, no-store")
      response.set_header("Referrer-Policy", "same-origin")
      response.set_header("X-Robots-Tag", "noindex, nofollow")
    end

    def invalid_email_login
      if action_name == "prepare"
        render_component_json Folio::Users::EmailLogin::ConfirmationComponent.new(invalid: true), status: :unprocessable_entity
      elsif request.format.json?
        body = { error: I18n.t("folio.users.email_login.invalid") }
        body[:data] = { state: "revoked" } if action_name == "status"
        render json: body, status: :unprocessable_entity
      else
        render Folio::Users::EmailLogin::ConfirmationComponent.new(invalid: true), status: :unprocessable_entity
      end
    end

    def turnstile_failure_redirect_path
      main_app.new_user_email_login_path
    end

    def recaptcha_failure_redirect_path
      main_app.new_user_email_login_path
    end
end
