# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::ConsoleNotesControllerTest < Folio::Console::BaseControllerTest
  attr_reader :site

  class ::Folio::Console::Api::ConsoleNotesControllerTest::PageWithConsoleNotes < Folio::Page
    include Folio::HasConsoleNotes
  end

  setup do
    @site = (Folio::Site.first || create(:folio_site))
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
    page = ::Folio::Console::Api::ConsoleNotesControllerTest::PageWithConsoleNotes.create!(title: "::Folio::Console::Api::ConsoleNotesControllerTest::PageWithConsoleNotes",
                                                                                           site:)
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

  test "react_update_target" do
    page = ::Folio::Console::Api::ConsoleNotesControllerTest::PageWithConsoleNotes.create!(title: "react_update_target", site:)


    assert_equal(0, page.console_notes.count)

    post react_update_target_console_api_console_notes_path, params: {
      target_id: page.id,
      target_type: "::Folio::Console::Api::ConsoleNotesControllerTest::PageWithConsoleNotes",
      console_notes_attributes: {
        "0" => {
          content: "<p>foo</p>"
        }
      }
    }
    assert_response(:ok)
    assert_equal 1, response.parsed_body["data"]["react"]["notes"].size
  end
end
