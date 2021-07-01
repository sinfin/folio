# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::BreadcrumbsCellTest < Cell::TestCase
  test "show" do
    html = cell("dummy/ui/breadcrumbs", nil).(:show)
    assert_not html.has_css?(".d-ui-breadcrumbs")

    crumbs = [
      OpenStruct.new(path: "/foo", name: "foo", options: {}),
      OpenStruct.new(path: "/bar", name: "bar", options: {}),
    ]
    html = cell("dummy/ui/breadcrumbs", crumbs).(:show)
    assert html.has_css?(".d-ui-breadcrumbs")
  end
end
