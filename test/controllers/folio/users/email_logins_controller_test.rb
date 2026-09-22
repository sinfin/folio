# frozen_string_literal: true

require "test_helper"

class Folio::Users::EmailLoginsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  def setup
    travel_to Time.current
    @site = create_and_host_site
    @password = "Complex@Password.123"
    @user = create(:folio_user, auth_site: @site, password: @password)
    clear_enqueued_jobs
  end

  test "password login waits for email approval without authenticating or changing Trackable" do
    with_email_login do
      assert_difference("Folio::Users::EmailLoginChallenge.count", 1) do
        assert_no_difference("@user.reload.sign_in_count") { start_password_login }
      end
      assert_redirected_to main_app.user_email_login_path
      assert_nil controller.warden.user(:user)
      assert_nil Folio::Current.user
      assert_nil @user.reload.current_sign_in_at
      assert_nil @user.remember_created_at
      assert_empty @user.trusted_browsers
      assert_enqueued_jobs 1, only: Folio::Users::EmailLoginDeliveryJob
    end
  end

  test "JSON password login returns the waiting URL expected by the existing modal" do
    with_email_login do
      post main_app.user_session_path(format: :json), params: { user: { email: @user.email, password: @password } }
      assert_response :ok
      assert_equal main_app.user_email_login_path, response.parsed_body.dig("data", "url")
      assert_nil controller.warden.user(:user)
    end
  end

  test "approval in a second browser signs in only the original browser after its POST" do
    with_email_login do
      start_password_login
      token = delivery_token
      challenge = @user.email_login_challenges.last
      phone = open_session
      phone.host! @site.env_aware_domain

      phone.post main_app.prepare_user_email_login_path, params: { email_login_token: token }, as: :json
      phone.assert_response :ok
      assert_nil challenge.reload.approved_at

      phone.post main_app.approve_user_email_login_path, params: { challenge_id: @user.email_login_challenges.last.id }
      phone.assert_response :ok
      assert_not_nil challenge.reload.approved_at
      assert_nil phone.controller.warden.user(:user)
      assert_equal 0, @user.reload.sign_in_count

      phone.post main_app.complete_user_email_login_path
      phone.assert_response :unprocessable_entity
      assert_nil phone.controller.warden.user(:user)

      get main_app.status_user_email_login_path(format: :json)
      assert_equal "approved", response.parsed_body.dig("data", "state")
      assert_nil controller.warden.user(:user)
      assert_equal 0, @user.reload.sign_in_count

      post main_app.complete_user_email_login_path
      assert_response :redirect
      assert_equal @user, controller.warden.user(:user)
      assert_equal 1, @user.reload.sign_in_count
      assert_not_nil challenge.reload.consumed_at
      assert_equal 1, @user.trusted_browsers.count

      post main_app.complete_user_email_login_path
      assert_response :redirect
      assert_equal 1, @user.reload.sign_in_count
    end
  end

  test "one click approval signs in the original browser without rendering the confirmation form" do
    with_email_login do
      start_password_login

      post main_app.prepare_user_email_login_path,
           params: { email_login_token: delivery_token, approve: "1" }, as: :json

      assert_response :ok
      assert_equal controller.after_sign_in_path_for(@user), response.parsed_body.dig("data", "url")
      assert_equal @user, controller.warden.user(:user)
      assert_not_nil @user.email_login_challenges.sole.consumed_at
      assert_equal 1, @user.reload.sign_in_count
    end
  end

  test "one click approval on another device approves only the original browser" do
    with_email_login do
      start_password_login
      challenge = @user.email_login_challenges.sole
      phone = open_session
      phone.host! @site.env_aware_domain

      phone.post main_app.prepare_user_email_login_path,
                 params: { email_login_token: delivery_token, approve: "1" }, as: :json

      phone.assert_response :ok
      assert_includes phone.response.parsed_body.fetch("data"), "f-users-email-login-confirmation"
      assert_not_nil challenge.reload.approved_at
      assert_nil phone.controller.warden.user(:user)
      assert_equal 0, @user.reload.sign_in_count

      post main_app.complete_user_email_login_path
      assert_equal @user, controller.warden.user(:user)
      assert_equal 1, @user.reload.sign_in_count
    end
  end

  test "lifecycle metrics count approval and completion once without recording proofs" do
    events = []
    subscriber = ->(*args) { events << args.last }
    with_email_login do
      ActiveSupport::Notifications.subscribed(subscriber, "email_login.folio") do
        start_password_login
        token = delivery_token
        post main_app.prepare_user_email_login_path, params: { email_login_token: token }, as: :json
        2.times { post main_app.approve_user_email_login_path, params: { challenge_id: @user.email_login_challenges.last.id } }
        2.times { post main_app.complete_user_email_login_path }
        assert_equal %w[created approved completed], events.map { |event| event[:event] }
        events.each do |event|
          assert_equal({ site_id: @site.id, purpose: "password", count: 1, kind: "counter" }, event.except(:event))
        end
        assert_not_includes events.to_json, token
        assert_not_includes events.to_json, controller.session[Folio::Devise::EmailLogin::SESSION_KEY]["browser_nonce"]
      end
    end
  end

  test "wrong passwords retain Devise lockable behavior without creating email challenges" do
    with_email_login do
      assert_no_difference("Folio::Users::EmailLoginChallenge.count") do
        post main_app.user_session_path, params: { user: { email: @user.email, password: "wrong" } }
      end
      assert_equal 1, @user.reload.failed_attempts
      assert_no_enqueued_jobs only: Folio::Users::EmailLoginDeliveryJob
    end
  end

  test "failed CAPTCHA cannot issue an email challenge before the login action" do
    with_email_login do
      with_failed_captcha do
        assert_no_difference("Folio::Users::EmailLoginChallenge.count") { start_password_login }
        assert_response :unprocessable_entity
        assert_nil controller.warden.user(:user)
        assert_equal 0, @user.reload.sign_in_count
        assert_no_enqueued_jobs only: Folio::Users::EmailLoginDeliveryJob
      end
    end
  end

  test "failed CAPTCHA cannot authenticate an already trusted browser" do
    with_email_login do
      start_password_login
      post main_app.prepare_user_email_login_path, params: { email_login_token: delivery_token }, as: :json
      post main_app.approve_user_email_login_path, params: { challenge_id: @user.email_login_challenges.last.id }
      post main_app.complete_user_email_login_path
      get main_app.destroy_user_session_path
      trust = @user.trusted_browsers.last
      previous_login = trust.last_authenticated_at
      travel 1.hour

      with_failed_captcha do
        assert_no_difference("@user.reload.sign_in_count") { start_password_login }
        assert_response :unprocessable_entity
        assert_nil controller.warden.user(:user)
        assert_equal previous_login, trust.reload.last_authenticated_at
      end
    end
  end

  test "magic link uses the same approval flow without a password" do
    with_email_login do
      post main_app.user_email_login_path, params: { user: { email: @user.email } }
      assert_redirected_to main_app.user_email_login_path
      assert_equal "magic_link", @user.email_login_challenges.last.purpose
      post main_app.prepare_user_email_login_path, params: { email_login_token: delivery_token }, as: :json
      post main_app.approve_user_email_login_path, params: { challenge_id: @user.email_login_challenges.last.id }
      assert_nil controller.warden.user(:user)
      post main_app.complete_user_email_login_path, params: { trust_browser: "0" }
      assert_equal @user, controller.warden.user(:user)
      assert_empty @user.trusted_browsers
    end
  end

  test "unknown email returns the same waiting response without creating an account" do
    with_email_login do
      assert_no_difference("Folio::User.count") do
        post main_app.user_email_login_path, params: { user: { email: "unknown@example.test" } }
      end
      assert_redirected_to main_app.user_email_login_path
      get main_app.status_user_email_login_path(format: :json)
      assert_equal "waiting", response.parsed_body.dig("data", "state")
      assert_no_enqueued_jobs only: Folio::Users::EmailLoginDeliveryJob
    end
  end

  test "magic link request for a pending invitation resends the invitation" do
    @user.invite!
    previous_created_at = @user.invitation_created_at
    clear_enqueued_jobs
    travel 1.minute

    with_email_login do
      assert_no_difference("Folio::Users::EmailLoginChallenge.count") do
        post main_app.user_email_login_path, params: { user: { email: @user.email } }
      end

      assert_redirected_to main_app.user_email_login_path
      assert_operator @user.reload.invitation_created_at, :>, previous_created_at
      assert_enqueued_emails 1
      assert_nil controller.warden.user(:user)
      get main_app.status_user_email_login_path(format: :json)
      assert_equal "waiting", response.parsed_body.dig("data", "state")
    end
  end

  test "magic link entry is opt in and keeps the page that opened the login modal" do
    get main_app.new_user_session_path
    assert_select "a[href*='/users/email_login/new']", count: 0

    with_email_login do
      get main_app.new_user_session_path
      assert_select "a[href*='/users/email_login/new']", minimum: 1
      get main_app.new_user_email_login_path, headers: { "HTTP_REFERER" => "http://#{@site.env_aware_domain}/auction/item?tab=detail" }
      assert_select ".f-users-email-login-request"
      post main_app.user_email_login_path, params: { user: { email: @user.email } }
      assert_equal "/auction/item?tab=detail", @user.email_login_challenges.last.return_path
    end
  end

  test "external referrers never become the return path" do
    with_email_login do
      get main_app.new_user_email_login_path, headers: { "HTTP_REFERER" => "https://example.invalid/auction" }
      post main_app.user_email_login_path, params: { user: { email: @user.email } }
      assert_nil @user.email_login_challenges.last.return_path
    end
  end

  test "mail limits match for known and unknown addresses across browsers" do
    with_email_login do
      [@user.email, "unknown-#{SecureRandom.hex(8)}@example.test"].each do |email|
        original = open_session
        original.host! @site.env_aware_domain
        original.post main_app.user_email_login_path(format: :json), params: { user: { email: } }
        original.assert_response :ok
        other = open_session
        other.host! @site.env_aware_domain
        other.post main_app.user_email_login_path(format: :json), params: { user: { email: " #{email.upcase} " } }
        other.assert_response :too_many_requests
        assert_equal "60", other.response.headers["Retry-After"]
        assert_equal I18n.t("folio.users.email_login.throttled"), other.response.parsed_body["error"]
      end
    end
  end

  test "expired known and unknown requests reject resends identically" do
    with_email_login do
      browsers = [@user.email, "unknown-#{SecureRandom.hex(8)}@example.test"].map do |email|
        browser = open_session
        browser.host! @site.env_aware_domain
        browser.post main_app.user_email_login_path(format: :json), params: { user: { email: } }
        browser.assert_response :ok
        browser
      end
      travel 10.minutes
      assert_no_enqueued_jobs only: Folio::Users::EmailLoginDeliveryJob do
        browsers.each do |browser|
          browser.post main_app.resend_user_email_login_path(format: :json)
          browser.assert_response :unprocessable_entity
          assert_equal I18n.t("folio.users.email_login.invalid"), browser.response.parsed_body["error"]
        end
      end
    end
  end

  test "throttled HTML resend keeps the waiting form and polling scripts" do
    with_email_login do
      start_password_login
      challenge = @user.email_login_challenges.last
      assert_no_enqueued_jobs only: Folio::Users::EmailLoginDeliveryJob do
        post main_app.resend_user_email_login_path, params: { trust_browser: "0" }
      end
      assert_response :too_many_requests
      assert_equal "60", response.headers["Retry-After"]
      assert_select ".f-users-email-login-waiting"
      assert_select "[role='alert']", text: I18n.t("folio.users.email_login.throttled")
      assert_nil challenge.reload.revoked_at
      assert_nil controller.warden.user(:user)
      get main_app.user_email_login_path
      assert_response :ok
      assert_select "input[name='trust_browser'][type='checkbox'][checked]", count: 0
    end
  end

  test "rate limit outage on a remembered public visit cannot bypass verification" do
    @user.update_column(:remember_created_at, 1.second.ago)
    post main_app.user_session_path, params: { user: { email: @user.email, password: @password, remember_me: "1" } }
    assert_equal @user, controller.warden.user(:user)
    cookies.delete(Rails.application.config.session_options[:key])

    with_email_login do
      unavailable = ->(**_options) { raise Folio::Devise::EmailLogin::Unavailable }
      Folio::Devise::EmailLogin::DeliveryLimit.stub(:consume!, unavailable) do
        assert_no_difference("@user.reload.sign_in_count") { get main_app.root_path }
        assert_response :service_unavailable
        assert_nil controller.warden.user(:user)
        assert_empty @user.email_login_challenges
      end
    end
  end

  test "rate limit outage cannot bypass verification or create a session" do
    with_email_login do
      unavailable = ->(**_options) { raise Folio::Devise::EmailLogin::Unavailable }
      Folio::Devise::EmailLogin::DeliveryLimit.stub(:consume!, unavailable) do
        assert_no_difference("Folio::Users::EmailLoginChallenge.count") { start_password_login }
        assert_response :service_unavailable
        assert_nil controller.warden.user(:user)
        assert_equal 0, @user.reload.sign_in_count
      end
    end
  end

  test "the configured log filter redacts both original-browser and approval secrets" do
    with_email_login do
      start_password_login
      filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
      assert_equal "[FILTERED]", filter.filter(controller.session.to_h).dig(Folio::Devise::EmailLogin::SESSION_KEY, "browser_nonce")
      post main_app.prepare_user_email_login_path, params: { email_login_token: delivery_token }, as: :json
      assert_equal "[FILTERED]", filter.filter(controller.session.to_h).dig(Folio::Devise::EmailLogin::APPROVAL_SESSION_KEY, "email_login_token")
    end
  end

  test "the token entry point uses the site layout with external scripts disabled" do
    with_email_login do
      start_password_login
      follow_redirect!
      assert_response :ok
      assert_select ".f-users-email-login-waiting"
      assert_includes response.headers["Cache-Control"], "no-store"
      assert_equal "same-origin", response.headers["Referrer-Policy"]
      assert_select "script[src*='folio/users/email_login']", count: 0

      get main_app.confirm_user_email_login_path
      assert_response :ok
      assert_select ".f-users-email-login-confirmation"
      assert_select ".d-layout-main .f-users-email-login-confirmation"
      assert_select "script[src*='email_login']", count: 0
      assert_includes response.headers["Content-Security-Policy"], "script-src 'self' 'unsafe-inline'"
      assert_select "form[action='/users/email_login/approve']", count: 0
      assert_not_includes response.body, delivery_token
      assert_includes response.headers["Cache-Control"], "no-store"
      assert_equal "same-origin", response.headers["Referrer-Policy"]
      assert_nil @user.email_login_challenges.last.approved_at
    end
  end

  test "manual checks and resend preserve opting out of browser trust" do
    with_email_login do
      start_password_login
      post main_app.complete_user_email_login_path, params: { trust_browser: "0" }
      assert_redirected_to main_app.user_email_login_path
      follow_redirect!
      assert_select "input[name='trust_browser'][checked]", count: 0
      assert_nil controller.warden.user(:user)

      travel 61.seconds
      post main_app.resend_user_email_login_path, params: { trust_browser: "0" }
      assert_redirected_to main_app.user_email_login_path
      assert_equal false, @user.email_login_challenges.last.trust_browser
      follow_redirect!
      assert_select "input[name='trust_browser'][checked]", count: 0
    end
  end

  test "confirming in the original browser returns to waiting without authenticating" do
    with_email_login do
      start_password_login
      post main_app.prepare_user_email_login_path, params: { email_login_token: delivery_token }, as: :json
      post main_app.approve_user_email_login_path, params: { challenge_id: @user.email_login_challenges.last.id }
      assert_redirected_to main_app.user_email_login_path
      assert_nil controller.warden.user(:user)
      follow_redirect!
      assert_select ".f-users-email-login-waiting"
      assert_nil controller.warden.user(:user)

      post main_app.complete_user_email_login_path
      assert_response :redirect
      path = URI(response.location).path
      get main_app.status_user_email_login_path(format: :json)
      assert_equal "consumed", response.parsed_body.dig("data", "state")
      assert_equal path, response.parsed_body.dig("data", "url")
      assert_equal 1, @user.reload.sign_in_count
    end
  end

  test "approval and completion enforce CSRF including the resend form action" do
    with_email_login do
      start_password_login
      challenge = @user.email_login_challenges.last
      previous_protection = Dummy::Folio::Users::EmailLoginsController.allow_forgery_protection
      previous_origin_check = Dummy::Folio::Users::EmailLoginsController.forgery_protection_origin_check
      Dummy::Folio::Users::EmailLoginsController.forgery_protection_origin_check = true
      Dummy::Folio::Users::EmailLoginsController.allow_forgery_protection = true
      begin
        get main_app.user_email_login_path
        assert controller.send(:protect_against_forgery?), "CSRF protection must be active for this test"
        assert_select "input[name='authenticity_token']", minimum: 1
        form_token = css_select("form[action='/users/email_login/complete'] input[name='authenticity_token']").first["value"]
        assert_raises(ActionController::InvalidAuthenticityToken) { delete main_app.user_email_login_path }
        assert_raises(ActionController::InvalidAuthenticityToken) { post main_app.resend_user_email_login_path }
        assert_nil challenge.reload.revoked_at
        travel 61.seconds
        post main_app.resend_user_email_login_path, params: { authenticity_token: form_token }
        assert_response :redirect
        assert_not_nil challenge.reload.revoked_at
        token = delivery_token(job: enqueued_jobs.last)
        challenge = @user.email_login_challenges.last

        phone = open_session
        phone.host! @site.env_aware_domain
        phone.get main_app.confirm_user_email_login_path
        csrf_token = phone.css_select("meta[name='csrf-token']").first["content"]
        assert_raises(ActionController::InvalidAuthenticityToken) do
          phone.post main_app.prepare_user_email_login_path, params: { email_login_token: token }, as: :json
        end
        assert_nil phone.session[Folio::Devise::EmailLogin::APPROVAL_SESSION_KEY]
        phone.post main_app.prepare_user_email_login_path, params: { email_login_token: token },
                   headers: { "X-CSRF-Token" => csrf_token }, as: :json
        phone.assert_response :ok
        approval_html = Nokogiri::HTML.fragment(phone.response.parsed_body.fetch("data"))
        approval_token = approval_html.at_css("form input[name='authenticity_token']")["value"]
        assert_raises(ActionController::InvalidAuthenticityToken) { phone.post main_app.approve_user_email_login_path }
        assert_nil challenge.reload.approved_at
        ["null", "https://example.invalid"].each do |origin|
          assert_raises(ActionController::InvalidAuthenticityToken) do
            phone.post main_app.approve_user_email_login_path,
                       params: { authenticity_token: approval_token, challenge_id: challenge.id }, headers: { "Origin" => origin }
          end
          assert_nil challenge.reload.approved_at
        end
        phone.post main_app.approve_user_email_login_path,
                   params: { authenticity_token: approval_token, challenge_id: challenge.id },
                   headers: { "Origin" => "http://#{@site.env_aware_domain}" }
        phone.assert_response :ok

        assert_raises(ActionController::InvalidAuthenticityToken) { post main_app.complete_user_email_login_path }
        assert_nil challenge.reload.consumed_at
        post main_app.complete_user_email_login_path, params: { authenticity_token: form_token }
        assert_response :redirect
        assert_equal @user, controller.warden.user(:user)
      ensure
        Dummy::Folio::Users::EmailLoginsController.allow_forgery_protection = previous_protection
        Dummy::Folio::Users::EmailLoginsController.forgery_protection_origin_check = previous_origin_check
      end
    end
  end

  test "remembered sign-in on an untrusted browser waits and does not repeatedly send email" do
    # Devise requires the cookie timestamp to be strictly newer, even when time is frozen.
    @user.update_column(:remember_created_at, 1.second.ago)
    post main_app.user_session_path, params: { user: { email: @user.email, password: @password, remember_me: "1" } }
    assert_equal @user, controller.warden.user(:user)
    assert cookies["remember_user_token"].present?
    remembered = controller.request.cookie_jar.signed["remember_user_token"]
    assert_equal @user, Folio::User.serialize_from_cookie(*remembered)
    cookies.delete(Rails.application.config.session_options[:key])
    assert_nil cookies[Rails.application.config.session_options[:key]]

    with_email_login do
      assert_difference("Folio::Users::EmailLoginChallenge.count", 1) do
        assert_no_difference("@user.reload.sign_in_count") do
          get main_app.root_path
          assert controller.request.cookie_jar.signed["remember_user_token"].present?, "remember cookie reaches the next request"
          assert_nil controller.warden.user(:user)
          assert_redirected_to main_app.user_email_login_path
        end
      end
      assert_redirected_to main_app.user_email_login_path
      assert_nil controller.warden.user(:user)
      assert_equal "rememberable", @user.email_login_challenges.last.purpose
      assert_equal main_app.root_path, @user.email_login_challenges.last.return_path

      assert_no_difference("Folio::Users::EmailLoginChallenge.count") do
        2.times do
          get main_app.user_email_login_path
          assert_response :ok
          get main_app.status_user_email_login_path(format: :json)
          assert_equal "waiting", response.parsed_body.dig("data", "state")
          assert_nil controller.warden.user(:user)
        end
      end
    end
  end

  test "email approval never restores a remembered account on the approving device" do
    phone_user = create(:folio_user, auth_site: @site, password: @password)
    phone_user.update_column(:remember_created_at, 1.second.ago)
    phone = open_session
    phone.host! @site.env_aware_domain
    phone.post main_app.user_session_path, params: { user: { email: phone_user.email, password: @password, remember_me: "1" } }
    assert phone.cookies["remember_user_token"].present?
    assert_equal phone_user, Folio::User.serialize_from_cookie(*phone.controller.request.cookie_jar.signed["remember_user_token"])
    phone.cookies.delete(Rails.application.config.session_options[:key])

    with_email_login do
      start_password_login
      assert_no_difference("Folio::Users::EmailLoginChallenge.count") do
        phone.post main_app.prepare_user_email_login_path, params: { email_login_token: delivery_token }, as: :json
        phone.post main_app.approve_user_email_login_path, params: { challenge_id: @user.email_login_challenges.last.id }
        phone.assert_response :ok
      end
      assert_nil phone.controller.warden.user(:user)
      assert_not_nil @user.email_login_challenges.last.approved_at
      assert_equal 1, phone_user.reload.sign_in_count
    end
  end

  test "revoking browser trust affects only the signed in user and keeps the current session" do
    with_email_login do
      start_password_login
      post main_app.prepare_user_email_login_path, params: { email_login_token: delivery_token }, as: :json
      post main_app.approve_user_email_login_path, params: { challenge_id: @user.email_login_challenges.last.id }
      post main_app.complete_user_email_login_path
      version = @user.reload.email_authentication_version
      other = create(:folio_user, auth_site: @site)

      delete main_app.revoke_trusted_browsers_user_email_login_path, params: { user_id: other.id }

      assert_redirected_to main_app.users_registrations_edit_password_path
      assert_equal version + 1, @user.reload.email_authentication_version
      assert_equal 0, other.reload.email_authentication_version
      assert_equal @user, controller.warden.user(:user)
      assert_predicate cookies["folio_trusted_browser_#{@site.id}_#{@user.id}"], :blank?
      assert_not_nil @user.trusted_browsers.last.revoked_at
    end
  end

  test "anonymous requests cannot revoke any user's browser trust" do
    with_email_login do
      assert_no_difference("@user.reload.email_authentication_version") do
        delete main_app.revoke_trusted_browsers_user_email_login_path, params: { user_id: @user.id }
      end
      assert_redirected_to main_app.new_user_session_path
    end
  end

  test "a confirmation form cannot approve a different challenge opened in another tab" do
    with_email_login do
      start_password_login
      first = @user.email_login_challenges.last
      first_token = delivery_token
      phone = open_session
      phone.host! @site.env_aware_domain
      phone.post main_app.prepare_user_email_login_path, params: { email_login_token: first_token }, as: :json

      travel 61.seconds
      second_browser = open_session
      second_browser.host! @site.env_aware_domain
      second_browser.post main_app.user_session_path, params: { user: { email: @user.email, password: @password } }
      second = @user.email_login_challenges.last
      phone.post main_app.prepare_user_email_login_path, params: { email_login_token: delivery_token(job: enqueued_jobs.last) }, as: :json
      phone.post main_app.approve_user_email_login_path, params: { challenge_id: first.id }

      phone.assert_response :unprocessable_entity
      assert_nil first.reload.approved_at
      assert_nil second.reload.approved_at
      assert_equal "waiting", first.state

      phone.post main_app.prepare_user_email_login_path, params: { email_login_token: first_token }, as: :json
      phone.post main_app.approve_user_email_login_path, params: { challenge_id: first.id }
      phone.assert_response :ok
      assert_not_nil first.reload.approved_at
      assert_nil second.reload.approved_at
    end
  end

  %i[google_oauth2 apple].each do |provider|
    test "#{provider} keeps its original login when verification is disabled" do
      with_oauth_identity(provider) do
        assert_difference("@user.reload.sign_in_count", 1) { oauth_callback(provider) }
        assert_equal @user, controller.warden.user(:user)
        assert_empty @user.email_login_challenges
      end
    end

    test "#{provider} waits for email approval on an untrusted browser" do
      with_email_login do
        with_oauth_identity(provider) do
          assert_no_difference("@user.reload.sign_in_count") { oauth_callback(provider) }
          assert_redirected_to main_app.user_email_login_path
          assert_nil controller.warden.user(:user)
          assert_nil Folio::Current.user
          assert_equal "oauth", @user.email_login_challenges.last.purpose

          post main_app.prepare_user_email_login_path, params: { email_login_token: delivery_token }, as: :json
          post main_app.approve_user_email_login_path, params: { challenge_id: @user.email_login_challenges.last.id }
          post main_app.complete_user_email_login_path
          assert_equal @user, controller.warden.user(:user)
          assert_equal 1, @user.reload.sign_in_count
        end
      end
    end

    test "#{provider} can sign in on a trusted browser and extend its trust" do
      with_email_login do
        start_password_login
        post main_app.prepare_user_email_login_path, params: { email_login_token: delivery_token }, as: :json
        post main_app.approve_user_email_login_path, params: { challenge_id: @user.email_login_challenges.last.id }
        post main_app.complete_user_email_login_path
        trust = @user.trusted_browsers.last
        verified_at = trust.verified_at
        get main_app.destroy_user_session_path
        travel 29.days

        with_oauth_identity(provider) do
          assert_no_difference("Folio::Users::EmailLoginChallenge.count") { oauth_callback(provider) }
          assert_equal @user, controller.warden.user(:user)
          assert_equal Time.current, trust.reload.last_authenticated_at
          assert_equal verified_at, trust.verified_at
        end
      end
    end
  end

  test "creating an OAuth account waits for email verification before its first login" do
    with_email_login do
      email = "new-oauth-account@example.test"
      with_oauth_identity(:google_oauth2, user: nil, email: email) do
        oauth_callback(:google_oauth2)
        assert_redirected_to main_app.users_auth_new_user_path
        assert_difference("Folio::User.count", 1) do
          post main_app.users_auth_create_user_path, params: { user: { email: email, first_name: "New", last_name: "Account" } }
        end
        assert_redirected_to main_app.user_email_login_path
        user = Folio::User.find_by!(email: email, auth_site: @site)
        assert_nil controller.warden.user(:user)
        assert_nil Folio::Current.user
        assert_equal 0, user.sign_in_count
        assert_empty user.trusted_browsers
        challenge = user.email_login_challenges.sole
        assert_equal "oauth", challenge.purpose
        assert_nil challenge.approved_at

        post main_app.prepare_user_email_login_path, params: { email_login_token: delivery_token }, as: :json
        post main_app.approve_user_email_login_path, params: { challenge_id: challenge.id }
        post main_app.complete_user_email_login_path
        assert_response :redirect
        assert_equal user, controller.warden.user(:user)
        assert_equal 1, user.reload.sign_in_count
        assert_equal 1, user.trusted_browsers.count
      end
    end
  end

  test "resolving an OAuth account conflict cannot skip email login verification" do
    with_email_login do
      with_oauth_identity(:google_oauth2, user: nil) do
        oauth_callback(:google_oauth2)
        assert_redirected_to main_app.users_auth_conflict_path
        authentication = Folio::Omniauth::Authentication.find_by!(provider: "google_oauth2", conflict_user_id: @user.id)
        get main_app.users_auth_resolve_conflict_path(conflict_token: authentication.conflict_token)
        assert_redirected_to main_app.user_email_login_path
        assert_equal @user, authentication.reload.user
        assert_nil authentication.conflict_token
        assert_nil controller.warden.user(:user)
        assert_nil Folio::Current.user
        assert_equal 0, @user.reload.sign_in_count
        assert_empty @user.trusted_browsers
        challenge = @user.email_login_challenges.sole
        assert_equal "oauth", challenge.purpose
        assert_nil challenge.approved_at

        post main_app.prepare_user_email_login_path, params: { email_login_token: delivery_token }, as: :json
        post main_app.approve_user_email_login_path, params: { challenge_id: challenge.id }
        post main_app.complete_user_email_login_path
        assert_response :redirect
        assert_equal @user, controller.warden.user(:user)
        assert_equal 1, @user.reload.sign_in_count
        assert_equal 1, @user.trusted_browsers.count
      end
    end
  end

  test "resetting a password revokes old proofs and signs in without another email" do
    with_email_login do
      start_password_login
      challenge = @user.email_login_challenges.last
      token = @user.send_reset_password_instructions
      assert_no_difference("Folio::Users::EmailLoginChallenge.count") do
        assert_no_enqueued_jobs only: Folio::Users::EmailLoginDeliveryJob do
          put main_app.user_password_path, params: { user: { reset_password_token: token,
                                                           password: "Changed@Password123", password_confirmation: "Changed@Password123" } }
        end
      end
      assert_response :redirect
      assert_equal @user, controller.warden.user(:user)
      assert_equal 1, @user.reload.sign_in_count
      assert_equal 1, @user.email_authentication_version
      assert_not challenge.reload.usable_for?(@site)
      assert_empty @user.trusted_browsers

      get main_app.destroy_user_session_path
      put main_app.user_password_path, params: { user: { reset_password_token: token,
                                                       password: "Changed@Password456", password_confirmation: "Changed@Password456" } }
      assert_nil controller.warden.user(:user)
      assert_equal 1, @user.reload.sign_in_count
    end
  end

  test "accepting an invitation signs in without another email" do
    with_email_login do
      @user.invite!
      token = @user.raw_invitation_token
      assert_no_enqueued_jobs only: Folio::Users::EmailLoginDeliveryJob do
        put main_app.user_invitation_path, params: { user: { invitation_token: token,
                                                           password: @password, password_confirmation: @password } }
      end
      assert_response :redirect
      assert_predicate @user.reload, :invitation_accepted?
      assert_equal @site.id, @user.auth_site_id
      assert_equal @user, controller.warden.user(:user)
      assert_equal 1, @user.sign_in_count
      assert_empty @user.email_login_challenges
      assert_empty @user.trusted_browsers

      get main_app.destroy_user_session_path
      put main_app.user_invitation_path, params: { user: { invitation_token: token,
                                                         password: @password, password_confirmation: @password } }
      assert_nil controller.warden.user(:user)
      assert_equal 1, @user.reload.sign_in_count
    end
  end

  test "accepting an invitation with a changed email still requires proof of the new address" do
    with_email_login do
      @user.invite!
      token = @user.raw_invitation_token
      permitted = Folio::User.additional_controller_strong_params_for_create + [:email]
      Folio::User.stub(:additional_controller_strong_params_for_create, permitted) do
        Folio::User.stub(:reconfirmable, false) do
          put main_app.user_invitation_path, params: { user: { invitation_token: token,
                                                             email: "changed-invitation@example.test",
                                                             password: @password, password_confirmation: @password } }
        end
      end
      assert_equal "changed-invitation@example.test", @user.reload.email
      assert_redirected_to main_app.user_email_login_path
      assert_nil controller.warden.user(:user)
      assert_equal 0, @user.sign_in_count
      assert_enqueued_jobs 1, only: Folio::Users::EmailLoginDeliveryJob
    end
  end

  %i[invalid expired mismatched_password blocked_site foreign_site].each do |reason|
    test "password reset with #{reason} cannot create a session" do
      with_email_login do
        token = @user.send_reset_password_instructions
        token = "invalid-token" if reason == :invalid
        @user.update_column(:reset_password_sent_at, (Folio::User.reset_password_within + 1.minute).ago) if reason == :expired
        @user.site_user_links.find_or_create_by!(site: @site).update!(locked_at: Time.current) if reason == :blocked_site
        host! create_site(force: true).env_aware_domain if reason == :foreign_site
        assert_no_enqueued_jobs only: Folio::Users::EmailLoginDeliveryJob do
          put main_app.user_password_path, params: { user: { reset_password_token: token, password: "Changed@Password123",
                                                           password_confirmation: reason == :mismatched_password ? "different" : "Changed@Password123" } }
        end
        assert_nil controller.warden.user(:user)
        assert_equal 0, @user.reload.sign_in_count
        assert_empty @user.email_login_challenges
        assert_empty @user.trusted_browsers
      end
    end

    test "invitation with #{reason} cannot create a session" do
      with_email_login do
        @user.invite!
        token = reason == :invalid ? "invalid-token" : @user.raw_invitation_token
        @user.update_column(:invitation_created_at, 2.days.ago) if reason == :expired
        @user.site_user_links.find_or_create_by!(site: @site).update!(locked_at: Time.current) if reason == :blocked_site
        host! create_site(force: true).env_aware_domain if reason == :foreign_site
        Folio::User.stub(:invite_for, 1.day) do
          assert_no_enqueued_jobs only: Folio::Users::EmailLoginDeliveryJob do
            put main_app.user_invitation_path, params: { user: { invitation_token: token, password: @password,
                                                               password_confirmation: reason == :mismatched_password ? "different" : @password } }
          end
        end
        assert_equal @site.id, @user.reload.auth_site_id
        assert_nil controller.warden.user(:user)
        assert_equal 0, @user.reload.sign_in_count
        assert_empty @user.email_login_challenges
        assert_empty @user.trusted_browsers
      end
    end
  end

  { before: 30.days - 1.second, at: 30.days, after: 30.days + 1.second }.each do |boundary, elapsed|
    test "password login #{boundary} the thirty day boundary uses browser trust correctly" do
      with_email_login do
        start_password_login
        post main_app.prepare_user_email_login_path, params: { email_login_token: delivery_token }, as: :json
        post main_app.approve_user_email_login_path, params: { challenge_id: @user.email_login_challenges.last.id }
        post main_app.complete_user_email_login_path
        trust = @user.trusted_browsers.last
        verified_at = trust.verified_at
        get main_app.destroy_user_session_path
        travel elapsed

        assert_difference("Folio::Users::EmailLoginChallenge.count", boundary == :before ? 0 : 1) { start_password_login }
        if boundary == :before
          assert_equal @user, controller.warden.user(:user)
          assert_equal Time.current, trust.reload.last_authenticated_at
          assert_equal verified_at, trust.verified_at
          assert_includes response.headers["Set-Cookie"].to_s, "folio_trusted_browser_#{@site.id}_#{@user.id}"
        else
          assert_redirected_to main_app.user_email_login_path
          assert_nil controller.warden.user(:user)
          assert_equal verified_at, trust.reload.last_authenticated_at
        end
      end
    end
  end

  test "opening a link cannot prepare or approve a query token" do
    with_email_login do
      start_password_login
      token = delivery_token
      get main_app.confirm_user_email_login_path(email_login_token: token)
      assert_response :unprocessable_entity
      assert_nil session[Folio::Devise::EmailLogin::APPROVAL_SESSION_KEY]
      assert_nil @user.email_login_challenges.sole.approved_at
      assert_nil controller.warden.user(:user)
      assert_not_includes response.body, token
      assert_select "form[action='/users/email_login/approve']", count: 0
    end
  end

  test "preparation sends proof only in the POST body and can reload its approval context" do
    with_email_login do
      start_password_login
      token = delivery_token
      post main_app.prepare_user_email_login_path, params: { email_login_token: token }, as: :json
      assert_response :ok
      assert_not_includes request.fullpath, token
      assert_equal token, request.request_parameters["email_login_token"]
      assert_not_includes response.body, token
      html = Nokogiri::HTML.fragment(response.parsed_body.fetch("data"))
      assert_equal @user.email_login_challenges.sole.id.to_s, html.at_css("input[name='challenge_id']")["value"]
      assert_not_includes response.body, token
      assert_nil @user.email_login_challenges.sole.approved_at
      assert_nil controller.warden.user(:user)

      get main_app.confirm_user_email_login_path
      post main_app.prepare_user_email_login_path, as: :json
      assert_response :ok
      assert_nil @user.email_login_challenges.sole.approved_at
      assert_equal 0, @user.reload.sign_in_count
    end
  end

  test "preparation needs valid proof and rechecks it after resend" do
    with_email_login do
      start_password_login
      challenge = @user.email_login_challenges.sole
      post main_app.prepare_user_email_login_path, as: :json
      assert_response :unprocessable_entity

      post main_app.prepare_user_email_login_path, params: { email_login_token: delivery_token }, as: :json
      post main_app.prepare_user_email_login_path, as: :json
      assert_response :ok
      assert_includes response.parsed_body.fetch("data"), "/users/email_login/approve"
      assert_nil challenge.reload.approved_at

      travel 61.seconds
      post main_app.resend_user_email_login_path
      post main_app.prepare_user_email_login_path, as: :json
      assert_response :unprocessable_entity
      assert_not_includes response.parsed_body.fetch("data"), "/users/email_login/approve"
      assert_nil challenge.reload.approved_at
      assert_nil controller.warden.user(:user)
    end
  end

  test "a rejected replacement proof clears an older approval context" do
    with_email_login do
      start_password_login
      post main_app.prepare_user_email_login_path, params: { email_login_token: delivery_token }, as: :json
      assert_response :ok
      post main_app.prepare_user_email_login_path(email_login_token: delivery_token), as: :json
      assert_response :unprocessable_entity
      assert_nil session[Folio::Devise::EmailLogin::APPROVAL_SESSION_KEY]
      post main_app.prepare_user_email_login_path, as: :json
      assert_response :unprocessable_entity
      post main_app.approve_user_email_login_path, params: { challenge_id: @user.email_login_challenges.sole.id }
      assert_response :unprocessable_entity
      assert_nil @user.email_login_challenges.sole.approved_at
    end
  end

  test "HEAD on an email link neither stores approval nor authenticates" do
    with_email_login do
      start_password_login
      challenge = @user.email_login_challenges.last
      head main_app.confirm_user_email_login_path(email_login_token: delivery_token)
      assert_response :ok
      assert_empty response.body
      assert_nil session[Folio::Devise::EmailLogin::APPROVAL_SESSION_KEY]
      assert_nil challenge.reload.approved_at
      assert_nil controller.warden.user(:user)
    end
  end

  test "a browser without the original session cannot inspect or finish an approved login" do
    with_email_login do
      start_password_login
      token = delivery_token
      challenge = @user.email_login_challenges.last
      reset!
      host! @site.env_aware_domain
      post main_app.prepare_user_email_login_path, params: { email_login_token: token }, as: :json
      post main_app.approve_user_email_login_path, params: { challenge_id: challenge.id }
      assert_response :ok
      get main_app.status_user_email_login_path(format: :json)
      assert_response :unprocessable_entity
      assert_equal({ "state" => "revoked" }, response.parsed_body["data"])
      post main_app.complete_user_email_login_path
      assert_response :unprocessable_entity
      assert_nil challenge.reload.consumed_at
      assert_nil controller.warden.user(:user)
    end
  end

  test "expiration after approval prevents completion in the original browser" do
    with_email_login do
      start_password_login
      challenge = @user.email_login_challenges.last
      post main_app.prepare_user_email_login_path, params: { email_login_token: delivery_token }, as: :json
      post main_app.approve_user_email_login_path, params: { challenge_id: challenge.id }
      travel_to challenge.expires_at
      post main_app.complete_user_email_login_path
      assert_response :unprocessable_entity
      assert_nil controller.warden.user(:user)
      assert_nil challenge.reload.consumed_at
    end
  end

  test "email approval preserves an already signed in different account on that device" do
    phone_user = create(:folio_user, auth_site: @site, password: @password)
    phone = open_session
    phone.host! @site.env_aware_domain
    phone.post main_app.user_session_path, params: { user: { email: phone_user.email, password: @password } }
    assert_equal phone_user, phone.controller.warden.user(:user)

    with_email_login do
      start_password_login
      phone.post main_app.prepare_user_email_login_path, params: { email_login_token: delivery_token }, as: :json
      phone.post main_app.approve_user_email_login_path, params: { challenge_id: @user.email_login_challenges.last.id }
      phone.assert_response :ok
      assert_equal phone_user, phone.controller.warden.user(:user)
      post main_app.complete_user_email_login_path
      assert_equal @user, controller.warden.user(:user)
      assert_equal 1, phone_user.reload.sign_in_count
    end
  end

  test "signing in another account in the waiting browser cancels the original attempt" do
    with_email_login do
      start_password_login
      challenge = @user.email_login_challenges.last
      post main_app.prepare_user_email_login_path, params: { email_login_token: delivery_token }, as: :json
      post main_app.approve_user_email_login_path, params: { challenge_id: challenge.id }
      other_user = create(:folio_user, auth_site: @site)
      sign_in other_user
      post main_app.complete_user_email_login_path
      assert_response :unprocessable_entity
      assert_equal other_user, controller.warden.user(:user)
      assert_not_nil challenge.reload.revoked_at
      assert_nil challenge.consumed_at
      assert_empty @user.trusted_browsers
    end
  end

  ["invalid", ["invalid"], true].each do |invalid_user|
    test "malformed #{invalid_user.class} user parameters return a bad request" do
      with_email_login do
        assert_raises(ActionController::BadRequest) do
          post main_app.user_email_login_path, params: { user: invalid_user }, as: :json
        end
        assert_empty @user.email_login_challenges
        assert_no_enqueued_jobs only: Folio::Users::EmailLoginDeliveryJob
      end
    end
  end

  private
    def with_failed_captcha
      callback = ->(controller) { controller.render json: { error: "CAPTCHA failed" }, status: :unprocessable_entity }
      klass = Dummy::Folio::Users::SessionsController
      klass.before_action(callback, only: :create)
      yield
    ensure
      klass.skip_before_action(callback)
    end

    def with_oauth_identity(provider, user: @user, email: @user.email)
      mock = OmniAuth::AuthHash.new(provider: provider.to_s, uid: "email-login-#{@user.id}",
                                   info: { email: email, name: "Email login test" },
                                   credentials: { token: "email-login-test-provider-token" }, extra: { raw_info: {} })
      Folio::Omniauth::Authentication.from_omniauth_auth(mock).update!(user: user)
      previous = OmniAuth.config.mock_auth[provider]
      OmniAuth.config.mock_auth[provider] = mock
      yield
    ensure
      OmniAuth.config.mock_auth[provider] = previous
    end

    def oauth_callback(provider)
      get main_app.public_send("user_#{provider}_omniauth_callback_path"), env: { "omniauth.auth" => OmniAuth.config.mock_auth[provider] }
    end

    def with_email_login(&block)
      Rails.application.config.stub(:folio_users_email_login_verification_enabled, true) do
        Rails.application.config.stub(:folio_users_magic_link_enabled, true, &block)
      end
    end

    def start_password_login
      post main_app.user_session_path, params: { user: { email: @user.email, password: @password } }
    end

    def delivery_token(job: nil)
      job ||= enqueued_jobs.find { |candidate| candidate[:job] == Folio::Users::EmailLoginDeliveryJob }
      id, payload = job.fetch(:args)
      Folio::Users::EmailLoginDeliveryJob.send(:token_encryptor).decrypt_and_verify(payload, purpose: "email_login:#{id}")
    end
end
