# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::BreadcrumbsComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Ui::BreadcrumbsComponent.new(breadcrumbs: nil))
    assert_no_selector(".d-ui-breadcrumbs")

    crumbs = [
      OpenStruct.new(path: "/foo", name: "foo", options: {}),
      OpenStruct.new(path: "/bar", name: "bar", options: {}),
    ]

    render_inline(Dummy::Ui::BreadcrumbsComponent.new(breadcrumbs: crumbs))
    assert_selector(".d-ui-breadcrumbs")

    render_inline(Dummy::Ui::BreadcrumbsComponent.new(breadcrumbs: crumbs, single: true))
    assert_selector(".d-ui-breadcrumbs")
  end
end
