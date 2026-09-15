# frozen_string_literal: true

require "test_helper"

class Folio::Users::TrustedBrowserLoginTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    travel_to Time.current
    @site = create_and_host_site
    @password = "Complex@Password.123"
    @user = create(:folio_user, auth_site: @site, password: @password)
    clear_enqueued_jobs
  end

  test "HTTPS trust cookies are private host cookies and renew only after successful login" do
    https!
    with_verification do
      verify_browser
      header = trust_cookie_header
      assert_match(/; secure/i, header)
      assert_match(/; httponly/i, header)
      assert_match(/; samesite=lax/i, header)
      assert_match(/; path=\//i, header)
      assert_no_match(/; domain=/i, header)
      assert_equal 30.days.from_now, Time.httpdate(header[/expires=([^;]+)/i, 1])
      trust = @user.trusted_browsers.last
      original = trust.last_authenticated_at
      get main_app.destroy_user_session_path
      travel 1.day

      post main_app.user_session_path, params: { user: { email: @user.email, password: "wrong" } }
      assert_equal original, trust.reload.last_authenticated_at
      assert_empty trust_cookie_header
      login
      assert_equal @user, controller.warden.user(:user)
      assert_equal Time.current, trust.reload.last_authenticated_at
      assert_equal 30.days.from_now, Time.httpdate(trust_cookie_header[/expires=([^;]+)/i, 1])
    end
  end

  %i[missing altered other_user other_site].each do |scenario|
    test "#{scenario} cookie cannot establish browser trust" do
      with_verification do
        verify_browser
        token = cookies[trust_cookie_name]
        get main_app.destroy_user_session_path
        travel 61.seconds
        case scenario
        when :missing
          cookies.delete(trust_cookie_name)
        when :altered
          cookies[trust_cookie_name] = SecureRandom.hex(32)
        when :other_user
          @user = create(:folio_user, auth_site: @site, password: @password)
          cookies[trust_cookie_name] = token
        when :other_site
          @user.update!(superadmin: true)
          @site = create_site(force: true)
          host! @site.env_aware_domain
          cookies[trust_cookie_name] = token
        end

        assert_difference("@user.email_login_challenges.count", 1) { login }
        assert_nil controller.warden.user(:user)
        assert_redirected_to main_app.user_email_login_path
      end
    end
  end

  test "changing IP does not invalidate a valid browser cookie" do
    with_verification do
      verify_browser
      get main_app.destroy_user_session_path
      travel 1.day
      assert_no_difference("@user.email_login_challenges.count") do
        post main_app.user_session_path, params: { user: { email: @user.email, password: @password } },
                                        env: { "REMOTE_ADDR" => "192.0.2.50" }
      end
      assert_equal @user, controller.warden.user(:user)
    end
  end

  test "ordinary visits keep an active session without renewing expired browser trust" do
    with_verification do
      verify_browser
      trust = @user.trusted_browsers.last
      trust.update!(verified_at: 31.days.ago, last_authenticated_at: 31.days.ago)
      original = trust.last_authenticated_at
      assert_no_difference("@user.email_login_challenges.count") do
        assert_no_difference("@user.reload.sign_in_count") { get main_app.users_registrations_edit_password_path }
      end
      assert_response :ok
      assert_equal @user, controller.warden.user(:user)
      assert_equal original, trust.reload.last_authenticated_at
      assert_empty trust_cookie_header
    end
  end

  test "magic link always sends email and opting out revokes existing browser trust" do
    with_verification do
      verify_browser
      old_trust = @user.trusted_browsers.last
      get main_app.destroy_user_session_path
      travel 61.seconds
      assert_enqueued_jobs 1, only: Folio::Users::EmailLoginDeliveryJob do
        post main_app.user_email_login_path, params: { user: { email: @user.email } }
      end
      assert_nil controller.warden.user(:user)
      assert_no_enqueued_jobs only: Folio::Users::EmailLoginDeliveryJob do
        complete_verification(trust_browser: "0")
      end
      assert_equal @user, controller.warden.user(:user)
      assert_not_nil old_trust.reload.revoked_at
      assert cookies[trust_cookie_name].blank?
    end
  end

  test "password change keeps the authenticated session but revokes trust before the next login" do
    with_verification do
      verify_browser
      trust = @user.trusted_browsers.last
      new_password = "Changed@Password.456"
      patch main_app.users_registrations_update_password_path,
            params: { user: { current_password: @password, password: new_password, password_confirmation: new_password } }
      assert_response :redirect
      assert_equal @user, controller.warden.user(:user)
      assert_not trust.trusted_for?(user: @user.reload, site: @site)
      get main_app.users_registrations_edit_password_path
      assert_response :ok
      get main_app.destroy_user_session_path
      @password = new_password
      travel 61.seconds
      assert_difference("@user.email_login_challenges.count", 1) { login }
      assert_nil controller.warden.user(:user)
    end
  end

  test "anonymous password updates cannot use the authenticated bypass sign in path" do
    with_verification do
      assert_no_difference("@user.reload.email_authentication_version") do
        patch main_app.users_registrations_update_password_path,
              params: { user: { current_password: @password, password: "Changed@Password.456", password_confirmation: "Changed@Password.456" } }
      end
      assert_redirected_to main_app.new_user_session_path
      assert_nil request.env["warden"].user(:user)
    end
  end

  test "console password change preserves its verified session and invalidates old trust" do
    @user.update!(superadmin: true)
    with_verification do
      verify_browser
      trust = @user.trusted_browsers.sole
      new_password = "Changed@Password.456"
      assert_no_difference("@user.reload.sign_in_count") do
        assert_no_difference("@user.email_login_challenges.count") do
          patch folio.update_password_console_current_user_path,
                params: { user: { current_password: @password, password: new_password, password_confirmation: new_password } }
        end
      end
      assert_redirected_to folio.console_current_user_path
      follow_redirect!
      assert_response :ok
      assert_equal @user, controller.warden.user(:user)
      assert_not trust.trusted_for?(user: @user.reload, site: @site)
      assert @user.valid_password?(new_password)

      get main_app.destroy_user_session_path
      @password = new_password
      travel 61.seconds
      assert_difference("@user.email_login_challenges.count", 1) { login }
      assert_redirected_to main_app.user_email_login_path
      assert_nil controller.warden.user(:user)
    end
  end

  test "anonymous requests cannot change a console password or use its bypass sign in" do
    with_verification do
      assert_no_difference("@user.reload.email_authentication_version") do
        patch folio.update_password_console_current_user_path,
              params: { user: { current_password: @password, password: "Changed@Password.456", password_confirmation: "Changed@Password.456" } }
      end
      assert_redirected_to main_app.new_user_session_path
      assert_nil request.env["warden"].user(:user)
    end
  end

  private
    def with_verification(&block)
      Rails.application.config.stub(:folio_users_email_login_verification_enabled, true) do
        Rails.application.config.stub(:folio_users_magic_link_enabled, true, &block)
      end
    end

    def login
      post main_app.user_session_path, params: { user: { email: @user.email, password: @password } }
    end

    def verify_browser
      login
      assert_redirected_to main_app.user_email_login_path
      complete_verification
    end

    def complete_verification(trust_browser: "1")
      job = enqueued_jobs.reverse.find { |candidate| candidate[:job] == Folio::Users::EmailLoginDeliveryJob }
      id, payload = job.fetch(:args)
      token = Folio::Users::EmailLoginDeliveryJob.send(:token_encryptor).decrypt_and_verify(payload, purpose: "email_login:#{id}")
      post main_app.prepare_user_email_login_path, params: { email_login_token: token }, as: :json
      post main_app.approve_user_email_login_path, params: { challenge_id: id }
      post main_app.complete_user_email_login_path, params: { trust_browser: }
      assert_equal @user, controller.warden.user(:user)
    end

    def trust_cookie_name
      "folio_trusted_browser_#{@site.id}_#{@user.id}"
    end

    def trust_cookie_header
      Array(response.headers["Set-Cookie"]).flat_map { |value| value.split("\n") }.find { |value| value.start_with?("#{trust_cookie_name}=") }.to_s
    end
end
