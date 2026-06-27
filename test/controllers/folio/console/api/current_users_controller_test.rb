# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::CurrentUsersControllerTest < Folio::Console::BaseControllerTest
  include Folio::Engine.routes.url_helpers

  test "console_url_ping" do
    assert_nil superadmin.console_url
    assert_nil superadmin.console_url_updated_at

    post console_url_ping_console_api_current_user_url(format: :json), params: { url: "foo" }
    assert_response(:ok)
    assert_equal false, response.parsed_body["data"]["other_user_at_url"]

    superadmin.reload

    assert_equal "foo", superadmin.console_url
    assert superadmin.console_url_updated_at
  end

  test "console_url_ping returns other_user_at_url when another user edits the url" do
    other_user = create(:folio_user, :superadmin)
    other_user.update_console_url!("foo")

    post console_url_ping_console_api_current_user_url(format: :json), params: { url: "foo" }
    assert_response(:ok)
    assert_equal true, response.parsed_body["data"]["other_user_at_url"]
  end

  test "console_url_ping returns rendered warning bar html when another user edits the same record" do
    page = create(:folio_page)
    edit_url = edit_url_for(page)

    other_user = create(:folio_user, :superadmin)
    other_user.update_console_url!(edit_url)

    post console_url_ping_console_api_current_user_url(format: :json),
         params: { url: edit_url, placement_token: placement_token_for(page, edit_url) }

    assert_response(:ok)
    assert_equal true, response.parsed_body["data"]["other_user_at_url"]
    assert_includes response.parsed_body["data"]["bar_html"].to_s,
                    "f-c-current-users-console-url-bar"
  end

  test "console_url_ping renders the bar from the signed token without re-deriving the route" do
    page = create(:folio_page)
    # a nested/host-app style URL the API could not regenerate from the record alone
    nested_url = "http://test.host/console/blog/articles/1/comments/#{page.id}/edit"

    other_user = create(:folio_user, :superadmin)
    other_user.update_console_url!(nested_url)

    post console_url_ping_console_api_current_user_url(format: :json),
         params: { url: nested_url, placement_token: placement_token_for(page, nested_url) }

    assert_response(:ok)
    assert_equal true, response.parsed_body["data"]["other_user_at_url"]
    assert_includes response.parsed_body["data"]["bar_html"].to_s,
                    "f-c-current-users-console-url-bar"
  end

  test "console_url_ping omits warning bar html when the editor is alone" do
    page = create(:folio_page)
    edit_url = edit_url_for(page)

    post console_url_ping_console_api_current_user_url(format: :json),
         params: { url: edit_url, placement_token: placement_token_for(page, edit_url) }

    assert_response(:ok)
    assert_equal false, response.parsed_body["data"]["other_user_at_url"]
    assert_nil response.parsed_body["data"]["bar_html"]
  end

  test "console_url_ping does not render a bar when the token url does not match the pinged url" do
    page_a = create(:folio_page)
    page_b = create(:folio_page)
    edit_url_a = edit_url_for(page_a)
    edit_url_b = edit_url_for(page_b)

    other_user = create(:folio_user, :superadmin)
    other_user.update_console_url!(edit_url_a)

    # colliding on page_a, but the token is for page_b
    post console_url_ping_console_api_current_user_url(format: :json),
         params: { url: edit_url_a, placement_token: placement_token_for(page_b, edit_url_b) }

    assert_response(:ok)
    assert_equal true, response.parsed_body["data"]["other_user_at_url"]
    assert_nil response.parsed_body["data"]["bar_html"]
  end

  test "console_url_ping ignores a tampered placement token" do
    page = create(:folio_page)
    edit_url = edit_url_for(page)

    other_user = create(:folio_user, :superadmin)
    other_user.update_console_url!(edit_url)

    post console_url_ping_console_api_current_user_url(format: :json),
         params: { url: edit_url, placement_token: "not-a-valid-signed-token" }

    assert_response(:ok)
    assert_equal true, response.parsed_body["data"]["other_user_at_url"]
    assert_nil response.parsed_body["data"]["bar_html"]
  end

  test "console_url_ping ignores a signed token for a non-ActiveRecord type" do
    page = create(:folio_page)
    edit_url = edit_url_for(page)

    other_user = create(:folio_user, :superadmin)
    other_user.update_console_url!(edit_url)

    # validly signed but pointing at a real, non-AR constant — must be ignored, not raise
    token = placement_verifier.generate({ "type" => "String", "id" => "1", "url" => edit_url })
    post console_url_ping_console_api_current_user_url(format: :json),
         params: { url: edit_url, placement_token: token }

    assert_response(:ok)
    assert_equal true, response.parsed_body["data"]["other_user_at_url"]
    assert_nil response.parsed_body["data"]["bar_html"]
  end

  test "console_url_ping ignores other users with stale console_url" do
    other_user = create(:folio_user, :superadmin)
    other_user.update_columns(console_url: "foo",
                              console_url_updated_at: 10.minutes.ago)

    post console_url_ping_console_api_current_user_url(format: :json), params: { url: "foo" }
    assert_response(:ok)
    assert_equal false, response.parsed_body["data"]["other_user_at_url"]
  end

  test "console_url_clear clears console_url" do
    superadmin.update_console_url!("foo")

    post console_url_clear_console_api_current_user_url(format: :json), params: { url: "foo" }
    assert_response(:no_content)

    superadmin.reload

    assert_nil superadmin.console_url
    assert_nil superadmin.console_url_updated_at
  end

  test "console_url_clear keeps console_url when url param does not match" do
    superadmin.update_console_url!("bar")

    post console_url_clear_console_api_current_user_url(format: :json), params: { url: "foo" }
    assert_response(:no_content)

    superadmin.reload

    assert_equal "bar", superadmin.console_url
  end

  test "update_console_preference" do
    assert_nil superadmin.console_preferences

    post update_console_preferences_console_api_current_user_path(format: :json), params: {
      html_auto_format: true,
    }
    assert_response(:ok)

    superadmin.reload

    assert_equal true, response.parsed_body["data"]["html_auto_format"]
    assert_equal true, superadmin.console_preferences["html_auto_format"]

    post update_console_preferences_console_api_current_user_path(format: :json), params: {
      html_auto_format: false,
    }
    assert_response(:ok)

    superadmin.reload

    assert_equal false, response.parsed_body["data"]["html_auto_format"]
    assert_equal false, superadmin.console_preferences["html_auto_format"]
  end

  private
    # canonical (friendly-id / slug based) edit URL, matching what the heartbeat
    # reports and what the page signs into the placement token
    def edit_url_for(record)
      "http://test.host#{edit_console_page_path(record)}"
    end

    def placement_verifier
      Rails.application.message_verifier(
        Folio::Console::CurrentUsers::PresencePingComponent::PLACEMENT_VERIFIER_PURPOSE
      )
    end

    def placement_token_for(record, url)
      placement_verifier.generate({ "type" => record.class.name, "id" => record.id, "url" => url })
    end
end
