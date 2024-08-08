# frozen_string_literal: true

require "test_helper"

class Folio::Devise::SessionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "create (sign_in) without crossdomain => two users" do
    site1 = create(:folio_site, domain: "site1.localhost", type: "Folio::Site")
    site2 = create(:folio_site, domain: "site2.localhost", type: "Folio::Site")
    email = "franta@kocourek.cz"
    user_site1 = user_site2 = nil

    assert ::Folio.site_for_crossdomain_devise.nil?
    assert_nil ::Folio.main_site

    assert_difference("::Folio::User.count", 2) do
      user_site1 = register_user_at_site(site1, email:, first_name: "Site1", last_name: "User", password: "password1")
      user_site2 = register_user_at_site(site2, email:, first_name: "Site2", last_name: "User", password: "password2")
    end

    assert_not_equal user_site1, user_site2
    assert_not_equal user_site1.source_site, user_site2.source_site

    # let try to sign in to sites
    assert can_sign_in_at_site?(site1, email:, password: "password1")
    assert_not can_sign_in_at_site?(site1, email:, password: "password2")
    assert_not can_sign_in_at_site?(site2, email:, password: "password1")
    assert can_sign_in_at_site?(site2, email:, password: "password2")
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
        # File.write("response.html", response.body)

        user_site = ::Folio::User.where(source_site: site, email:).first
        user_site.update(first_name:, last_name:, password:, password_confirmation: password)
        user_site.accept_invitation!

        assert user_site.reload.invitation_accepted?
      end
      user_site
    end

    def can_sign_in_at_site?(site, email:, password:)
      host_site site
      puts("Trying to sign in at #{site.env_aware_domain} with #{email} and #{password}")
      post user_session_url(only_path: false, host: site.env_aware_domain),
           params: { user: { email:, password: } }

      # not signed in?
      return false if response.redirect? && response.location == user_session_url(only_path: false, host: site.env_aware_domain)

      follow_redirect!
      assert_response :success

      get destroy_user_session_url(only_path: false, host: site.env_aware_domain)
      true
    rescue StandardError
      false
    end
end
