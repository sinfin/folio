# frozen_string_literal: true

require "test_helper"

class Folio::Devise::CrossdomainHandlerTest < ActiveSupport::TestCase
  test "always noop with nil master_site" do
    result = new_result(master_site: nil)
    assert_equal :noop, result.action
  end

  test "master_site - no session data" do
    result = new_result(master_site: current_site)
    assert_equal :noop, result.action
  end

  test "master_site - valid params and no user" do
    token = make_devise_token

    result = new_result(master_site: current_site, params: {
      crossdomain: token,
      site: "target-site-slug",
      resource_name: "user",
    })

    assert_equal :redirect_to_sessions_new, result.action

    assert session.present?

    assert_equal "user",
                 session[Folio::Devise::CrossdomainHandler::SESSION_KEY][:resource_name]

    assert_equal "target-site-slug",
                 session[Folio::Devise::CrossdomainHandler::SESSION_KEY][:target_site_slug]

    assert_equal token,
                 session[Folio::Devise::CrossdomainHandler::SESSION_KEY][:token]
  end

  test "master_site - valid params and signed in user" do
    token = make_devise_token
    user = create(:folio_user)

    result = new_result(master_site: current_site, current_resource: user, params: {
      crossdomain: token,
      site: "target-site-slug",
    })

    assert_equal :sign_in_on_target_site, result.action

    user.reload
    assert user.crossdomain_devise_token
    assert user.crossdomain_devise_set_at

    assert result.params
    assert result.params[:crossdomain]
    assert_equal user.crossdomain_devise_token, result.params[:crossdomain_user]

    # clears session
    assert_nil session[Folio::Devise::CrossdomainHandler::SESSION_KEY]
  end

  test "master_site - valid session and no user" do
    token = make_devise_token

    make_session({ token:, target_site_slug: "target-site-slug", resource_name: "user" })
    result = new_result(master_site: current_site, session:)

    assert_equal :redirect_to_sessions_new, result.action

    assert session.present?

    assert_equal "user",
                 session[Folio::Devise::CrossdomainHandler::SESSION_KEY][:resource_name]

    assert_equal "target-site-slug",
                 session[Folio::Devise::CrossdomainHandler::SESSION_KEY][:target_site_slug]

    assert_equal token,
                 session[Folio::Devise::CrossdomainHandler::SESSION_KEY][:token]
  end

  test "master_site - noop for devise controllers" do
    %w[create new].each do |action_name|
      token = make_devise_token

      make_session({ token:, target_site_slug: "target-site-slug", resource_name: "user" })
      result = new_result(master_site: current_site,
                          session:,
                          controller_name: "sessions",
                          action_name:,
                          devise_controller: true)

      assert_equal :noop, result.action

      assert session.present?

      assert_equal "user",
                   session[Folio::Devise::CrossdomainHandler::SESSION_KEY][:resource_name]

      assert_equal "target-site-slug",
                   session[Folio::Devise::CrossdomainHandler::SESSION_KEY][:target_site_slug]

      assert_equal token,
                   session[Folio::Devise::CrossdomainHandler::SESSION_KEY][:token]
    end
  end

  test "master_site - valid session and signed in user" do
    token = make_devise_token
    user = create(:folio_user)

    make_session({ token:, target_site_slug: "target-site-slug", resource_name: "user" })
    result = new_result(master_site: current_site, current_resource: user, session:)

    assert_equal :sign_in_on_target_site, result.action

    user.reload
    assert user.crossdomain_devise_token
    assert user.crossdomain_devise_set_at

    assert result.params
    assert result.params[:crossdomain]
    assert_equal user.crossdomain_devise_token, result.params[:crossdomain_user]

    # clears session
    assert_nil session[Folio::Devise::CrossdomainHandler::SESSION_KEY]
  end

  test "master_site - no params/session and signed in user" do
    user = create(:folio_user)
    result = new_result(master_site: current_site, current_resource: user)

    assert_equal :noop, result.action
  end

  test "slave_site - valid params & session and no user" do
    token = make_devise_token
    user_token = make_devise_token

    user = create(:folio_user,
                  crossdomain_devise_token: user_token,
                  crossdomain_devise_set_at: 1.second.ago)

    make_session({ token:, timestamp: 10.seconds.ago, resource_name: "user" })

    result = new_result(master_site: master_site_mock,
                        current_resource: nil,
                        params: {
                          crossdomain: token,
                          crossdomain_user: user.crossdomain_devise_token,
                        })

    assert_equal :sign_in, result.action
    assert_equal user, result.resource

    # clears session
    assert_nil session[Folio::Devise::CrossdomainHandler::SESSION_KEY]
  end

  test "slave_site - valid params & session and no user in a devise controller" do
    token = make_devise_token
    user_token = make_devise_token

    user = create(:folio_user,
                  crossdomain_devise_token: user_token,
                  crossdomain_devise_set_at: 1.second.ago)

    make_session({ token:, timestamp: 10.seconds.ago, resource_name: "user" })

    result = new_result(master_site: master_site_mock,
                        current_resource: nil,
                        devise_controller: true,
                        params: {
                          crossdomain: token,
                          crossdomain_user: user.crossdomain_devise_token,
                        })

    assert_equal :sign_in, result.action
    assert_equal user, result.resource

    # clears session
    assert_nil session[Folio::Devise::CrossdomainHandler::SESSION_KEY]
  end

  test "slave_site - valid params & session and no user, but crossdomain_devise_set_at set too long ago" do
    token = make_devise_token
    user_token = make_devise_token

    user = create(:folio_user,
                  crossdomain_devise_token: user_token,
                  crossdomain_devise_set_at: 1.day.ago)

    make_session({ token:, timestamp: 10.seconds.ago, resource_name: "user" })

    result = new_result(master_site: master_site_mock,
                        current_resource: nil,
                        params: {
                          crossdomain: token,
                          crossdomain_user: user.crossdomain_devise_token,
                        })

    assert_equal :noop, result.action
  end

  test "slave_site - valid params+session and signed_in user" do
    user = create(:folio_user)
    result = new_result(master_site: master_site_mock, current_resource: user)

    assert_equal :noop, result.action
  end

  test "slave_site - devise controller - sessions for users" do
    result = new_result(master_site: master_site_mock,
                        devise_controller: true,
                        controller_name: "sessions")

    assert_equal :redirect_to_master_sessions_new, result.action
  end

  test "slave_site - devise controller - sessions for accounts" do
    result = new_result(master_site: master_site_mock,
                        devise_controller: true,
                        resource_name: :account,
                        controller_name: "sessions")

    assert_equal :redirect_to_master_sessions_new, result.action
  end

  test "slave_site - devise controller - registrations/invitations" do
    %w[registrations invitations].each do |controller_name|
      result = new_result(master_site: master_site_mock,
                          devise_controller: true,
                          controller_name:)

      assert_equal :redirect_to_master_invitations_new, result.action
    end
  end

  private
    MockRequest = Struct.new(:host, :path, :path_parameters, keyword_init: true)

    def request
      MockRequest.new(host: current_site.env_aware_domain,
                      path: "/",
                      path_parameters: { controller: "home", action: "index" })
    end

    def session
      @session ||= {}
    end

    def current_site
      @current_site ||= create_current_site
    end

    def master_site
      nil
    end

    def master_site_mock
      Folio::Site.new(domain: "folio-master.com",
                      slug: "folio-master")
    end

    def current_resource
      nil
    end

    def params
      {}
    end

    def set_user_crossdomain_data!(user)
      user.update_columns(crossdomain_devise_token: Devise.friendly_token[0,
                          TOKEN_LENGTH],
                          crossdomain_devise_set_at: Time.current)
    end

    def create_current_site
      create(:folio_site)
    end

    def new_result(request: nil,
                   session: nil,
                   current_site: nil,
                   current_resource: nil,
                   master_site: nil,
                   controller_name: nil,
                   action_name: nil,
                   params: nil,
                   devise_controller: false,
                   resource_name: :user)
      Folio::Devise::CrossdomainHandler.new(request: request || self.request,
                                            session: session || self.session,
                                            current_site: current_site || self.current_site,
                                            params: params || self.params,
                                            current_resource: current_resource || self.current_resource,
                                            master_site: master_site || self.master_site,
                                            controller_name: controller_name || "home",
                                            action_name: action_name || "index",
                                            devise_controller:,
                                            resource_name:).handle_before_action!
    end

    def make_session(h)
      @session = { Folio::Devise::CrossdomainHandler::SESSION_KEY => h.stringify_keys }
    end

    def make_devise_token
      Devise.friendly_token[0, Folio::Devise::CrossdomainHandler::TOKEN_LENGTH]
    end
end
