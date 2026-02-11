# frozen_string_literal: true

require "test_helper"

class Folio::Console::CatalogueSortArrowsComponentTest < Folio::Console::ComponentTest
  class SortablePage < Folio::Page
    scope :sort_by_title_asc, -> { order(title: :asc) }
    scope :sort_by_title_desc, -> { order(title: :desc) }
  end

  test "render? returns false when klass does not have sort scopes" do
    component = Folio::Console::CatalogueSortArrowsComponent.new(klass: Folio::Page, attr: :title)

    assert_not component.render?
  end

  test "render? returns true when klass has sort scopes" do
    component = Folio::Console::CatalogueSortArrowsComponent.new(klass: SortablePage, attr: :title)

    assert component.render?
  end

  test "render" do
    with_controller_class(Folio::Console::BaseController) do
      with_request_url "/console" do
        component = Folio::Console::CatalogueSortArrowsComponent.new(klass: SortablePage, attr: :title)

        render_inline(component)

        assert_selector(".f-c-catalogue-sort-arrows")
      end
    end
  end
end
