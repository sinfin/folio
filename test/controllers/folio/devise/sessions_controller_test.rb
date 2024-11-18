# frozen_string_literal: true

require "test_helper"

class Folio::Devise::SessionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "create (sign_in) without crossdomain => two users" do
    site1 = create(:folio_site, domain: "site1.localhost", type: "Folio::Site")
    site2 = create(:folio_site, domain: "site2.localhost", type: "Folio::Site")
    email = "franta@kocourek.cz"
    user_site1 = user_site2 = nil

    Rails.application.config.stub(:folio_crossdomain_devise, false) do
      assert_difference("::Folio::User.count", 2) do
        user_site1 = register_user_at_site(site1, email:, first_name: "Site1", last_name: "User", password: "password1")
        user_site2 = register_user_at_site(site2, email:, first_name: "Site2", last_name: "User", password: "password2")
      end

      assert_not_equal user_site1, user_site2
      assert_not_equal user_site1.auth_site, user_site2.auth_site

      # let try to sign in to sites
      assert can_sign_in_at_site?(site1, email:, password: "password1")
      assert_not can_sign_in_at_site?(site1, email:, password: "password2")
      assert_not can_sign_in_at_site?(site2, email:, password: "password1")
      assert can_sign_in_at_site?(site2, email:, password: "password2")
    end
  end

  test "create (sign_in) without crossdomain superadmin have one account on main site for all sites" do
    site1 = create(:folio_site, domain: "site1.localhost", type: "Folio::Site")
    site2 = create(:folio_site, domain: "site2.localhost", type: "Folio::Site")
    main_site = create(:folio_site, domain: "main.localhost", type: "Folio::Site")
    email = "superadmin@kocourek.cz"
    _superadmin = create(:folio_user, email:, password: "password1", superadmin: true, auth_site: main_site)

    Rails.application.config.stub(:folio_crossdomain_devise, false) do
      Folio.stub(:main_site, main_site) do
        # let try to sign in to sites
        assert can_sign_in_at_site?(main_site, email:, password: "password1")
        assert can_sign_in_at_site?(site1, email:, password: "password1")
        assert can_sign_in_at_site?(site2, email:, password: "password1")
      end
    end
  end


  test "create (sign_in) with crossdomain => one user" do
    site1 = create(:folio_site, domain: "site1.localhost", type: "Folio::Site")
    site2 = create(:folio_site, domain: "site2.localhost", type: "Folio::Site")
    xdomain_site = create(:folio_site, domain: "xdomain.localhost", type: "Folio::Site")
    email = "franta@kocourek.cz"
    user_site1 = user_site2 = nil

    Rails.application.config.stub(:folio_crossdomain_devise, true) do
      ::Folio.stub(:site_for_crossdomain_devise, xdomain_site) do
        # assert_difference("::Folio::User.count", 1) do
        user_site1 = register_user_through_xdomain_site(site1, email:, first_name: "Site1", last_name: "User", password: "password1")
        user_site2 = register_user_through_xdomain_site(site2, email:, first_name: "Site2", last_name: "User", password: "password2")
        # end

        assert_equal user_site1, user_site2
        assert_equal ::Folio.site_for_crossdomain_devise, user_site1.auth_site

        # let try to sign in to sites ("password2" is invalid)
        assert can_sign_in_at_site?(site1, email:, password: "password1")
        assert_not can_sign_in_at_site?(site1, email:, password: "password2")
        assert can_sign_in_at_site?(site2, email:, password: "password1")
        assert_not can_sign_in_at_site?(site2, email:, password: "password2")
      end
    end
  end


  private
    def register_user_at_site(site, email:, first_name:, last_name:, password:)
      host_site site

      user_site = nil

      Rails.application.config.stub(:folio_users_publicly_invitable, true) do
        get new_user_invitation_url(only_path: false, host: site.env_aware_domain)

        assert_response :success

        post user_invitation_url(only_path: false,
                                  host: site.env_aware_domain),
                                  params: { user: { email: } }

        assert_redirected_to user_invitation_url(only_path: false, host: site.env_aware_domain)
        follow_redirect!

        user_site = ::Folio::User.where(auth_site: site, email:).first
        user_site.update(first_name:, last_name:, password:, password_confirmation: password)
        user_site.accept_invitation!

        assert user_site.reload.invitation_accepted?
      end
      user_site
    end

    def register_user_through_xdomain_site(auth_site, email:, first_name:, last_name:, password:)
      host_site auth_site

      xdomain_site = ::Folio.site_for_crossdomain_devise
      user_site = ::Folio::User.where(auth_site: xdomain_site, email:).first

      Rails.application.config.stub(:folio_users_publicly_invitable, true) do
        get new_user_invitation_url(only_path: false, host: site.env_aware_domain)

        assert response.redirect?
        uri = URI.parse(response.location)
        assert_equal xdomain_site.env_aware_domain, uri.host
        assert_equal new_user_invitation_path, uri.path
        assert uri.query.include?("crossdomain=")

        follow_redirect!

        assert_response :success

        post user_invitation_url(only_path: false,
                                  host: xdomain_site.env_aware_domain),
                                  params: { user: { email: } }

        if user_site.present? # already registered
          if user_site.invitation_accepted?
            assert_response :unprocessable_entity
            assert response.body.include?('<div class="invalid-feedback">E-mail již databáze obsahuje</div>')
          else
            assert_redirected_to user_invitation_url(only_path: false, host: xdomain_site.env_aware_domain)
            follow_redirect!
          end
        else # totaly new user
          assert_redirected_to user_invitation_url(only_path: false, host: xdomain_site.env_aware_domain)
          follow_redirect!

          user_site = ::Folio::User.where(auth_site: xdomain_site, email:).first
          user_site.update(first_name:, last_name:, password:, password_confirmation: password)
          user_site.accept_invitation!

          assert user_site.reload.invitation_accepted?
        end
      end
      user_site
    end

    def can_sign_in_at_site?(site, email:, password:)
      host_site site

      post user_session_url(only_path: false, host: site.env_aware_domain),
           params: { user: { email:, password: } }

      # not signed in?
      return false if response.redirect? && response.location.include?(new_user_session_path)

      follow_redirect!
      assert_response :success

      get destroy_user_session_url(only_path: false, host: site.env_aware_domain)
      true
    rescue StandardError
      false
    end
end
