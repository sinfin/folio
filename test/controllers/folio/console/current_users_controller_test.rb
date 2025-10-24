# frozen_string_literal: true

require "test_helper"

class Folio::Console::CurrentUsersControllerTest < Folio::Console::BaseControllerTest
  test "show (enabled and disabled)" do
    with_profile_enabled(true) do
      get folio.console_current_user_path
      assert_response(:ok)
      assert_select("h1", I18n.t("folio.console.current_users.show_component.title"))
    end

    with_profile_enabled(false) do
      assert_not folio.respond_to?(:console_current_user_path), "Route helper should not exist when disabled"
    end
  end

  test "update_email" do
    original_email = @superadmin.email

    assert_nil @superadmin.unconfirmed_email

    patch folio.update_email_console_current_user_path, params: {
      user: {
        email: "foo@bar.baz",
      }
    }
    assert_redirected_to(folio.console_current_user_path)

    @superadmin.reload

    assert_equal original_email, @superadmin.email
    assert_equal "foo@bar.baz", @superadmin.unconfirmed_email
  end

  test "update_password" do
    assert @superadmin.valid_password?("Complex@Password.123")

    assert_raises(ActionController::ParameterMissing) do
      patch folio.update_password_console_current_user_path
    end

    sign_in @superadmin
    patch folio.update_password_console_current_user_path, params: { user: {
      password: "Complex@Password.123456",
      password_confirmation: "Complex@Password.123456",
      current_password: "foo",
    } }
    assert_response(:ok, "Password not changed")
    assert_select(".f-c-ui-flash", I18n.t("folio.console.current_users.update_password.failure"))

    @superadmin.reload
    assert @superadmin.valid_password?("Complex@Password.123"), "Password should not be changed"
    assert_not @superadmin.valid_password?("Complex@Password.123456"), "Password should not be changed"

    sign_in @superadmin
    patch folio.update_password_console_current_user_path, params: { user: {
      password: "Complex@Password.123456",
      password_confirmation: "Complex@Password.123456",
      current_password: "Complex@Password.123",
    } }
    assert_redirected_to folio.console_current_user_path, "Password changed"
    follow_redirect!
    assert_response(:ok)
    assert_select(".f-c-ui-flash", I18n.t("folio.console.current_users.update_password.success"))

    @superadmin.reload

    assert_not @superadmin.valid_password?("Complex@Password.123"), "Password should be changed"
    assert @superadmin.valid_password?("Complex@Password.123456"), "Password should be changed"

    sign_in @superadmin
    patch folio.update_password_console_current_user_path, params: { user: {
      password: "Complex@Password.123456",
      password_confirmation: "Complex@Password.123456",
      current_password: "Complex@Password.123456",
    } }
    assert_response(:ok, "Password not changed - it's the same")
    assert_select(".f-c-ui-flash", I18n.t("folio.console.current_users.update_password.failure"))
  end

  private

  def with_profile_enabled(value)
    original_app = Rails.application.config.folio_console_current_user_profile_enabled
    original_engine = if defined?(Folio::Engine) && Folio::Engine.respond_to?(:config)
                        Folio::Engine.config.folio_console_current_user_profile_enabled
                      end

    Rails.application.config.folio_console_current_user_profile_enabled = value
    if defined?(Folio::Engine) && Folio::Engine.respond_to?(:config)
      Folio::Engine.config.folio_console_current_user_profile_enabled = value
    end
    reload_routes
    yield
  ensure
    Rails.application.config.folio_console_current_user_profile_enabled = original_app unless original_app.nil?
    if defined?(Folio::Engine) && Folio::Engine.respond_to?(:config)
      Folio::Engine.config.folio_console_current_user_profile_enabled = original_engine unless original_engine.nil?
    end
    reload_routes
  end

  def reload_routes
    if defined?(Folio::Engine)
      Folio::Engine.reload_routes! if Folio::Engine.respond_to?(:reload_routes!)
      Folio::Engine.routes_reloader.reload! if Folio::Engine.respond_to?(:routes_reloader)
    end
    Rails.application.reload_routes!
  end
end
