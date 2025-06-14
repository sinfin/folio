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
    superadmin.update!(superadmin: true, auth_site: site_a)

    Rails.application.config.stub(:folio_crossdomain_devise, true) do
      Folio::Current.stub(:site_for_crossdomain_devise, site_a) do
        begin
          other_site = create_site(key: try(:other_site_key), force: true)
        rescue ActiveRecord::RecordInvalid => e
          puts "Cannot create other_site! Try setting other_site_key in Folio::Users::SessionsControllerTest.class_eval to handle singletons in folio_site_default_test_factory."
          raise e
        end

        assert_difference("superadmin.reload.sign_in_count", 1) do
          host_site site_a
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
          host_site site_a
          post main_app.user_session_path, params: { user: @params }
          assert_response(:redirect)
        end
      end
    end
  end

  test "without crossdomain, superadmin auth_site can be any site" do
    site_a = @site

    superadmin = @user
    superadmin.update!(superadmin: true, auth_site: site_a)

    Rails.application.config.stub(:folio_crossdomain_devise, false) do
      begin
        other_site = create_site(key: try(:other_site_key), force: true)
      rescue ActiveRecord::RecordInvalid => e
        puts "Cannot create other_site! Try setting other_site_key in Folio::Users::SessionsControllerTest.class_eval to handle singletons in folio_site_default_test_factory."
        raise e
      end

      assert_difference("superadmin.reload.sign_in_count", 1) do
        host_site site_a
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
        host_site site_a
        post main_app.user_session_path, params: { user: @params }
        assert_response(:redirect)
      end
    end
  end

  test "without crossdomain, regular user auth_site works" do
    site_a = @site
    regular_user = @user
    regular_user.update!(superadmin: false, auth_site: site_a)

    Rails.application.config.stub(:folio_crossdomain_devise, false) do
      begin
        other_site = create_site(key: try(:other_site_key), force: true)
      rescue ActiveRecord::RecordInvalid => e
        puts "Cannot create other_site! Try setting other_site_key in Folio::Users::SessionsControllerTest.class_eval to handle singletons in folio_site_default_test_factory."
        raise e
      end

      assert_difference("regular_user.reload.sign_in_count", 1) do
        host_site site_a
        post main_app.user_session_path, params: { user: @params }
        assert_response(:redirect)
      end

      sign_out regular_user

      assert_difference("regular_user.reload.sign_in_count", 0) do
        host_site other_site
        post main_app.user_session_path, params: { user: @params }
        assert_response(:redirect)
      end

      sign_out regular_user
      regular_user.update!(auth_site: other_site)

      assert_difference("regular_user.reload.sign_in_count", 0) do
        host_site site_a
        post main_app.user_session_path, params: { user: @params }
        assert_response(:redirect)
      end

      sign_out regular_user

      assert_difference("regular_user.reload.sign_in_count", 1) do
        host_site other_site
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

  test "lockable" do
    user = create(:folio_user)
    assert_equal 0, user.failed_attempts
    assert_nil user.unlock_token
    assert_nil user.locked_at

    4.times do |i|
      post main_app.user_session_path, params: { user: { email: user.email, password: "foo" } }
      assert_redirected_to main_app.user_session_path

      user.reload

      assert_equal i + 1, user.failed_attempts
      assert_nil user.locked_at
      assert_not user.access_locked?
      assert user.active_for_authentication?
    end

    post main_app.user_session_path, params: { user: { email: user.email, password: "foo" } }
    assert_redirected_to main_app.user_session_path

    user.reload

    assert_equal 5, user.failed_attempts
    assert user.locked_at
    assert user.access_locked?
    assert_not user.active_for_authentication?

    travel_to 1.hour.from_now do
      assert user.locked_at
      assert_not user.access_locked?
      assert user.active_for_authentication?
    end
  end
end
