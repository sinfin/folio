# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::ConsoleNotesControllerTest < Folio::Console::BaseControllerTest
  class PageWithConsoleNotes < Folio::Page
    include Folio::HasConsoleNotes
  end

  test "toggle_closed_at - invalid" do
    note = create(:folio_console_note)

    note.update_columns(target_id: nil, target_type: nil)

    post url_for([:toggle_closed_at, :console, :api, note]), params: {
      closed: true,
    }

    assert_response :bad_request
    assert_equal "ActiveRecord::RecordInvalid", response.parsed_body["errors"][0]["title"]
  end

  test "toggle_closed_at - valid" do
    page = PageWithConsoleNotes.create!(title: "PageWithConsoleNotes")
    note = create(:folio_console_note, target: page)
    another_note = create(:folio_console_note, target: page)

    assert_nil note.closed_at

    post url_for([:toggle_closed_at, :console, :api, note]), params: {
      closed: true,
    }

    assert_response(:success)
    assert response.parsed_body["data"]["catalogue_tooltip"]
    assert note.reload.closed_at

    post url_for([:toggle_closed_at, :console, :api, another_note]), params: {
      closed: true,
    }

    assert_response(:success)
    assert response.parsed_body["data"]["catalogue_tooltip"]
    assert another_note.reload.closed_at

    post url_for([:toggle_closed_at, :console, :api, note]), params: {
      closed: false,
    }

    assert_response(:success)
    assert response.parsed_body["data"]["catalogue_tooltip"]
    assert_nil note.reload.closed_at
  end
end
