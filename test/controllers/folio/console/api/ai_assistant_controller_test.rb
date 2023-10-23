# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::AiAssistantControllerTest < Folio::Console::BaseControllerTest
  include Devise::Test::IntegrationHelpers
  include Folio::Engine.routes.url_helpers

  def setup
    create_and_host_site
    @admin = create(:folio_account)
    sign_in @admin
  end

  test "invalid" do
    record_without_assistant = create(:folio_page)

    post generate_response_console_api_ai_assistant_path

    assert_response 204

    post generate_response_console_api_ai_assistant_path, params: {
      prompt: "foo",
      record_id: record_without_assistant.id,
      record_klass: record_without_assistant.class
    }

    assert_response 500
  end
end
