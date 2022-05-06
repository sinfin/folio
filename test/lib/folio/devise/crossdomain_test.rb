# frozen_string_literal: true

require "test_helper"

class Folio::Devise::CrossdomainTest < ActiveSupport::TestCase
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
    })

    assert_equal :redirect_to_sessions_new, result.action

    assert session.present?

    assert_equal "target-site-slug",
                 session[Folio::Devise::Crossdomain::SESSION_KEY][:target_site_slug]

    assert_equal token,
                 session[Folio::Devise::Crossdomain::SESSION_KEY][:token]
  end

  test "master_site - valid params and signed in user" do
    token = make_devise_token
    user = create(:folio_user)

    result = new_result(master_site: current_site, current_user: user, params: {
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
    assert_nil session[Folio::Devise::Crossdomain::SESSION_KEY]
  end

  test "master_site - valid session and no user" do
    token = make_devise_token

    make_session({ crossdomain: token, target_site_slug: "target-site-slug" })
    result = new_result(master_site: current_site, session:)

    assert_equal :redirect_to_sessions_new, result.action

    assert session.present?

    assert_equal "target-site-slug",
                 session[Folio::Devise::Crossdomain::SESSION_KEY][:target_site_slug]

    assert_equal token,
                 session[Folio::Devise::Crossdomain::SESSION_KEY][:token]
  end

  test "master_site - valid session and signed in user" do
    token = make_devise_token
    user = create(:folio_user)

    make_session({ crossdomain: token, target_site_slug: "target-site-slug" })
    result = new_result(master_site: current_site, current_user: user, session:)

    assert_equal :sign_in_on_target_site, result.action

    user.reload
    assert user.crossdomain_devise_token
    assert user.crossdomain_devise_set_at

    assert result.params
    assert result.params[:crossdomain]
    assert_equal user.crossdomain_devise_token, result.params[:crossdomain_user]

    # clears session
    assert_nil session[Folio::Devise::Crossdomain::SESSION_KEY]
  end

  test "master_site - no params/session and signed in user" do
    user = create(:folio_user)
    result = new_result(master_site: current_site, current_user: user)

    assert_equal :noop, result.action
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

    def current_user
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

    def new_result(request: nil, session: nil, current_site: nil, current_user: nil, master_site: nil, params: nil)
      Folio::Devise::Crossdomain.new(request: request || self.request,
                                     session: session || self.session,
                                     current_site: current_site || self.current_site,
                                     params: params || self.params,
                                     current_user: current_user || self.current_user,
                                     master_site: master_site || self.master_site).handle!
    end

    def make_session(h)
      @session = { Folio::Devise::Crossdomain::SESSION_KEY => h }
    end

    def make_devise_token
      Devise.friendly_token[0, Folio::Devise::Crossdomain::TOKEN_LENGTH]
    end
end
