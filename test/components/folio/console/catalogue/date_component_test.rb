# frozen_string_literal: true

require "test_helper"

class Folio::Console::Catalogue::DateComponentTest < Folio::Console::ComponentTest
  test "renders nothing when value blank" do
    render_inline(Folio::Console::Catalogue::DateComponent.new(value: nil))

    assert_no_selector(".f-c-catalogue-date")
  end

  test "renders time with alert styling when threshold exceeded" do
    render_inline(Folio::Console::Catalogue::DateComponent.new(value: 1.second.ago))

    assert_selector(".f-c-catalogue-date")
    assert_no_selector(".f-c-catalogue-date--alert")
    assert_selector(".f-c-catalogue-date__time")

    render_inline(Folio::Console::Catalogue::DateComponent.new(value: 10.seconds.ago,
                                                                 alert_threshold: 1.second))

    assert_selector(".f-c-catalogue-date")
    assert_selector(".f-c-catalogue-date--alert")
    assert_selector(".f-c-catalogue-date__time")
  end

  test "renders date without time row" do
    render_inline(Folio::Console::Catalogue::DateComponent.new(value: Date.today))

    assert_selector(".f-c-catalogue-date")
    assert_no_selector(".f-c-catalogue-date--alert")
    assert_no_selector(".f-c-catalogue-date__time")

    render_inline(Folio::Console::Catalogue::DateComponent.new(value: 2.days.ago.to_date,
                                                               alert_threshold: 1.day))

    assert_selector(".f-c-catalogue-date")
    assert_selector(".f-c-catalogue-date--alert")
    assert_no_selector(".f-c-catalogue-date__time")
  end
end
