# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::NotesControllerTest < Folio::Console::BaseControllerTest
  test "toggle_closed_at" do
    note = create(:folio_console_note)

    assert_nil note.closed_at

    post url_for([:toggle_closed_at, :console, :api, note]), params: {
      closed: true,
    }

    assert_response(:success)
    json = JSON.parse(response.body)
    assert json["data"]
    assert note.reload.closed_at

    post url_for([:toggle_closed_at, :console, :api, note]), params: {
      closed: false,
    }

    assert_response(:success)
    json = JSON.parse(response.body)
    assert json["data"]
    assert_nil note.reload.closed_at
  end
end
