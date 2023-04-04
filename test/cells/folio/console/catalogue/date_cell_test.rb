# frozen_string_literal: true

require "test_helper"

class Folio::Console::Catalogue::DateCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/catalogue/date", nil).(:show)
    assert_not html.has_css?(".f-c-catalogue-date")

    html = cell("folio/console/catalogue/date", 1.second.ago).(:show)
    assert html.has_css?(".f-c-catalogue-date")
    assert_not html.has_css?(".f-c-catalogue-date--alert")
    assert html.has_css?(".f-c-catalogue-date__time")

    html = cell("folio/console/catalogue/date", 10.seconds.ago, alert_threshold: 1.second).(:show)
    assert html.has_css?(".f-c-catalogue-date")
    assert html.has_css?(".f-c-catalogue-date--alert")
    assert html.has_css?(".f-c-catalogue-date__time")

    html = cell("folio/console/catalogue/date", Date.today).(:show)
    assert html.has_css?(".f-c-catalogue-date")
    assert_not html.has_css?(".f-c-catalogue-date--alert")
    assert_not html.has_css?(".f-c-catalogue-date__time")

    html = cell("folio/console/catalogue/date", 2.days.ago.to_date, alert_threshold: 1.day).(:show)
    assert html.has_css?(".f-c-catalogue-date")
    assert html.has_css?(".f-c-catalogue-date--alert")
    assert_not html.has_css?(".f-c-catalogue-date__time")
  end
end
