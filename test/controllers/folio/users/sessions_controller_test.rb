# frozen_string_literal: true

require "test_helper"

class Folio::Users::SessionsControllerTest < ActionDispatch::IntegrationTest
  TEST_PASSWORD = "Complex@Password.123"

  def setup
    @site = create_and_host_site

    @params = {
      email: "email@email.email",
      password: TEST_PASSWORD,
    }

    @user = create(:folio_user, @params)
  end

  test "new" do
    get main_app.new_user_session_path
    assert_response(:ok)
  end

  test "create" do
    post main_app.user_session_path, params: { user: @params }

    assert_redirected_to controller.after_sign_in_path_for(@user)
  end

  test "ajax create" do
    post main_app.user_session_path(format: :json), params: { user: @params }
    assert_response(:ok)
  end

  test "create pending invitation" do
    skip unless Rails.application.config.folio_users_publicly_invitable
    user = Folio::User.invite!(email: "invite@email.email", auth_site_id: ::Folio::Current.site.id)
    old_timestamp = user.invitation_created_at
    post main_app.user_session_path, params: { user: { email: "invite@email.email" } }
    assert_redirected_to user_invitation_path
    assert_not_equal old_timestamp, user.reload.invitation_created_at
  end

  test "ajax create pending invitation" do
    skip unless Rails.application.config.folio_users_publicly_invitable
    user = Folio::User.invite!(email: "invite@email.email", auth_site_id: ::Folio::Current.site.id)
    old_timestamp = user.invitation_created_at
    post main_app.user_session_path(format: :json), params: { user: { email: "invite@email.email" } }
    assert_response(:ok)
    assert_equal user_invitation_path, response.parsed_body["data"]["url"]
    assert_not_equal old_timestamp, user.reload.invitation_created_at
  end

  test "with crossdomain enabled, superadmins must have auth_site = main_site" do
    site_a = @site

    superadmin = @user
    superadmin.update!(superadmin: true, auth_site: main_site)

    Rails.application.config.stub(:folio_crossdomain_devise, true) do
      Folio::Current.stub(:site_for_crossdomain_devise, main_site) do
        other_site = create_site(force: true)

        assert_difference("superadmin.reload.sign_in_count", 1) do
          host_site main_site
          post main_app.user_session_path, params: { user: @params }
          assert_response(:redirect)
        end

        sign_out superadmin

        assert_difference("superadmin.reload.sign_in_count", 1) do
          host_site other_site
          post main_app.user_session_path, params: { user: @params }
          assert_response(:redirect)
        end

        sign_out superadmin
        superadmin.update!(auth_site: other_site)

        assert_no_difference("superadmin.reload.sign_in_count", "should not sign in when auth_site isn't site_for_crossdomain_devise") do
          host_site other_site
          post main_app.user_session_path, params: { user: @params }
          assert_response(:redirect)
        end

        sign_out superadmin

        assert_no_difference("superadmin.reload.sign_in_count",  "should not sign in when auth_site isn't site_for_crossdomain_devise") do
          host_site main_site
          post main_app.user_session_path, params: { user: @params }
          assert_response(:redirect)
        end
      end
    end
  end

  test "without crossdomain, superadmin auth_site can be any site" do
    main_site = @site

    superadmin = @user
    superadmin.update!(superadmin: true, auth_site: main_site)

    Rails.application.config.stub(:folio_crossdomain_devise, false) do
      other_site = create_site(force: true)

      assert_difference("superadmin.reload.sign_in_count", 1) do
        host_site main_site
        post main_app.user_session_path, params: { user: @params }
        assert_response(:redirect)
      end

      sign_out superadmin

      assert_difference("superadmin.reload.sign_in_count", 1) do
        host_site other_site
        post main_app.user_session_path, params: { user: @params }
        assert_response(:redirect)
      end

      sign_out superadmin
      superadmin.update!(auth_site: other_site)

      assert_difference("superadmin.reload.sign_in_count", 1, "should sign in even when auth_site isn't site_for_crossdomain_devise") do
        host_site other_site
        post main_app.user_session_path, params: { user: @params }
        assert_response(:redirect)
      end

      sign_out superadmin

      assert_difference("superadmin.reload.sign_in_count", 1, "should sign in even when auth_site isn't site_for_crossdomain_devise") do
        host_site main_site
        post main_app.user_session_path, params: { user: @params }
        assert_response(:redirect)
      end
    end
  end

  test "destroy" do
    sign_in @user
    get main_app.destroy_user_session_path
    assert_redirected_to main_app.send(Rails.application.config.folio_users_after_sign_out_path)
  end
end
