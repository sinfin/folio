# frozen_string_literal: true

require "test_helper"

class Folio::HasConsoleUrlTest < ActiveSupport::TestCase
  attr_reader :user, :other_user

  def setup
    super

    I18n.with_locale(:cs) do
      @user = create(:folio_user)
      @other_user = create(:folio_user)
    end
  end

  test "update_console_url! stores url and timestamp" do
    assert_nil user.console_url
    assert_nil user.console_url_updated_at

    user.update_console_url!("http://example.com/console/pages/1/edit")

    assert_equal "http://example.com/console/pages/1/edit", user.console_url
    assert_not_nil user.console_url_updated_at
  end

  test "currently_editing_url scope returns users editing the url" do
    url = "http://example.com/console/pages/1/edit"

    user.update_console_url!(url)

    assert_includes Folio::User.currently_editing_url(url), user
    assert_not_includes Folio::User.currently_editing_url(url), other_user
  end

  test "currently_editing_url scope excludes users with stale timestamps" do
    url = "http://example.com/console/pages/1/edit"

    user.update_columns(console_url: url, console_url_updated_at: 10.minutes.ago)

    assert_not_includes Folio::User.currently_editing_url(url), user
  end

  test "rewrite_console_url returns original url when no rewriter configured" do
    url = "http://example.com/console/homepages/future"

    assert_equal url, Folio::HasConsoleUrl.rewrite_console_url(url)
  end

  test "rewrite_console_url applies configured rewriter lambda" do
    with_console_url_rewriter do
      assert_equal "http://example.com/console/homepages/*",
                   Folio::HasConsoleUrl.rewrite_console_url("http://example.com/console/homepages/future")

      assert_equal "http://example.com/console/homepages/*",
                   Folio::HasConsoleUrl.rewrite_console_url("http://example.com/console/homepages/current")

      assert_equal "http://example.com/console/pages/1/edit",
                   Folio::HasConsoleUrl.rewrite_console_url("http://example.com/console/pages/1/edit")
    end
  end

  test "update_console_url! applies rewriter before storing" do
    with_console_url_rewriter do
      user.update_console_url!("http://example.com/console/homepages/future")

      assert_equal "http://example.com/console/homepages/*", user.console_url
    end
  end

  test "currently_editing_url scope applies rewriter for matching" do
    with_console_url_rewriter do
      # User stores rewritten URL
      user.update_console_url!("http://example.com/console/homepages/future")
      assert_equal "http://example.com/console/homepages/*", user.console_url

      # Query with different variant should still match
      assert_includes Folio::User.currently_editing_url("http://example.com/console/homepages/current"), user
      assert_includes Folio::User.currently_editing_url("http://example.com/console/homepages/future"), user
    end
  end

  test "update_console_url! handles nil url" do
    user.update_console_url!("http://example.com/console/pages/1/edit")
    assert_not_nil user.console_url

    user.update_console_url!(nil)

    assert_nil user.console_url
    assert_not_nil user.console_url_updated_at
  end

  test "update_console_url! handles nil url with rewriter configured" do
    with_console_url_rewriter do
      user.update_console_url!("http://example.com/console/homepages/future")
      assert_not_nil user.console_url

      user.update_console_url!(nil)

      assert_nil user.console_url
      assert_not_nil user.console_url_updated_at
    end
  end

  private
    def with_console_url_rewriter
      rewriter = ->(url) { url.gsub(%r{/homepages/(future|current)\z}, "/homepages/*") }
      original = Rails.application.config.folio_rewriter_lambda_for_has_console_url
      Rails.application.config.folio_rewriter_lambda_for_has_console_url = rewriter
      yield
    ensure
      Rails.application.config.folio_rewriter_lambda_for_has_console_url = original
    end
end
