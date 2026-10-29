# frozen_string_literal: true

require "test_helper"

class Folio::Console::CatalogueSortArrowsCellTest < Folio::Console::CellTest
  class SortablePage < Folio::Page
    scope :sort_by_title_asc, -> { order(title: :asc) }
    scope :sort_by_title_desc, -> { order(title: :desc) }
  end

  test "show" do
    html = cell("folio/console/catalogue_sort_arrows", klass: Folio::Page, attr: :title).(:show)
    assert_not html.has_css?(".f-c-catalogue-sort-arrows")

    html = cell("folio/console/catalogue_sort_arrows", klass: SortablePage, attr: :title).(:show)
    assert html.has_css?(".f-c-catalogue-sort-arrows")
  end

  test "link starts ascending sorting" do
    html = render_sort_link

    assert_equal "/console/pages?filter=published&sort=title_asc",
                 html.find(".f-c-catalogue-sort-arrows")[:href]
    assert_equal I18n.t("folio.console.catalogue_sort_arrows.sort_asc"),
                 html.find(".f-c-catalogue-sort-arrows")[:title]
  end

  test "link switches ascending sorting to descending" do
    html = render_sort_link(sort: "title_asc")

    assert_equal "/console/pages?filter=published&sort=title_desc",
                 html.find(".f-c-catalogue-sort-arrows")[:href]
    assert_equal I18n.t("folio.console.catalogue_sort_arrows.sort_desc"),
                 html.find(".f-c-catalogue-sort-arrows")[:title]
  end

  test "link cancels descending sorting" do
    html = render_sort_link(sort: "title_desc")

    assert_equal "/console/pages?filter=published",
                 html.find(".f-c-catalogue-sort-arrows")[:href]
    assert_equal I18n.t("folio.console.catalogue_sort_arrows.cancel_sort"),
                 html.find(".f-c-catalogue-sort-arrows")[:title]
  end

  test "link cancels descending sorting without an empty query string" do
    html = render_sort_link(sort: "title_desc", filter: false)

    assert_equal "/console/pages",
                 html.find(".f-c-catalogue-sort-arrows")[:href]
  end

  private
    def render_sort_link(sort: nil, filter: true)
      query_parameters = { "page" => "2" }
      query_parameters["filter"] = "published" if filter
      query_parameters["sort"] = sort if sort
      sort_cell = cell("folio/console/catalogue_sort_arrows", klass: SortablePage, attr: :title)
      parent_controller = sort_cell.context[:controller]
      parent_controller.request.set_header("PATH_INFO", "/console/pages")
      parent_controller.request.set_header("action_dispatch.request.query_parameters", query_parameters)
      parent_controller.params = query_parameters
      sort_cell.(:show)
    end
end
