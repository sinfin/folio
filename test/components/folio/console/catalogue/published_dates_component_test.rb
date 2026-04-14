# frozen_string_literal: true

require "test_helper"

class Folio::Console::Catalogue::PublishedDatesComponentTest < Folio::Console::ComponentTest
  test "renders nothing when record blank" do
    render_inline(Folio::Console::Catalogue::PublishedDatesComponent.new(record: nil))

    assert_no_selector(".f-c-catalogue-published-dates")
  end

  test "renders for folio page" do
    page = create(:folio_page)

    render_inline(Folio::Console::Catalogue::PublishedDatesComponent.new(record: page))

    assert_selector(".f-c-catalogue-published-dates")
  end
end
