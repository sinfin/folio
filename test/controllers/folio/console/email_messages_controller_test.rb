# frozen_string_literal: true

require "test_helper"

class Folio::Console::EmailMessagesControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get console_email_messages_url
    assert_response :success
    create(:emailbutler_message)
    get console_email_messages_url
    assert_response :success
  end
end
