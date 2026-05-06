# frozen_string_literal: true

require "test_helper"

class Folio::Devise::Sessions::NewCellTest < Cell::TestCase
  def render_show
    cell("folio/devise/sessions/new",
         resource: Folio::User.new,
         resource_name: :user).(:show)
  end

  test "show" do
    assert render_show.has_css?(".f-devise-sessions-new")
  end

  test "dev login button is hidden by default (no credentials configured)" do
    Rails.env.stub :development?, true do
      assert_not render_show.has_css?(".f-devise__dev-login")
    end
  end

  test "dev login button is hidden outside development even with credentials configured" do
    creds = { email: "dev@example.com", password: "s3cret" }
    with_folio_config(:folio_devise_dev_login_credentials, creds) do
      assert_not render_show.has_css?(".f-devise__dev-login")
    end
  end

  test "dev login button renders in development when credentials are configured" do
    Rails.env.stub :development?, true do
      creds = { email: "dev@example.com", password: "s3cret" }
      with_folio_config(:folio_devise_dev_login_credentials, creds) do
        button = render_show.find(".f-devise__dev-login")
        assert_includes button.text, "dev@example.com"
        assert_equal "button", button["type"]
        assert_equal "dev@example.com", button["data-dev-login-email"]
        assert_equal "s3cret", button["data-dev-login-password"]
        assert_includes button["onclick"], "this.dataset.devLoginEmail"
        assert_includes button["onclick"], "this.dataset.devLoginPassword"
        assert_includes button["onclick"], "name*=\\'email\\'"
        assert_includes button["onclick"], "name*=\\'password\\'"
      end
    end
  end

  private
    def with_folio_config(key, value)
      config = Rails.application.config
      previous = config.respond_to?(key) ? config.public_send(key) : nil
      config.public_send("#{key}=", value)
      yield
    ensure
      config.public_send("#{key}=", previous)
    end
end
