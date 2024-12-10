# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::UrlRedirectsControllerTest < Folio::Console::BaseControllerTest
  test "demo" do
    [
      build(:folio_url_redirect),
      create(:folio_url_redirect)
    ].each do |url_redirect|
      post folio.demo_console_api_url_redirects_path(id: url_redirect.id, format: :json), params: {
        url_redirect: {
          title: url_redirect.title,
          url_from: url_redirect.url_from,
          url_to: url_redirect.url_to,
          status_code: url_redirect.status_code,
          published: url_redirect.published,
          match_query: url_redirect.match_query,
          pass_query: url_redirect.pass_query,
        }
      }

      assert_response :ok
      assert response.parsed_body["data"].include?("f-c-url-redirects-fields-demo")
    end
  end
end
