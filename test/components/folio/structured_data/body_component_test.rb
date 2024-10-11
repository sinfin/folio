# frozen_string_literal: true

require "test_helper"

class Folio::StructuredData::BodyComponentTest < Folio::ComponentTest
  def setup
    @record = create(:folio_page)
    @breadcrumbs = []
  end

  test "render website structured data with breadcrumbs" do
    create_and_host_site

    @breadcrumbs.push(OpenStruct.new(name: @record.title, path: "/page1", options: {}))
    render_inline(Folio::StructuredData::BodyComponent.new(record: @record, breadcrumbs: @breadcrumbs))

    assert_selector 'script[type="application/ld+json"]', visible: false
    json = JSON.parse(page.find('script[type="application/ld+json"]', visible: false).text(:all))
    assert_equal "https://schema.org", json["@context"]
    assert_equal "WebSite", json["@graph"].first["@type"]

    breadcrumb_data = json["@graph"].find { |item| item["@type"] == "BreadcrumbList" }
    assert_not_nil breadcrumb_data
    assert_equal 2, breadcrumb_data["itemListElement"].size
  end

  test "render website structured data without breadcrumbs" do
    create_and_host_site

    render_inline(Folio::StructuredData::BodyComponent.new(record: @record, breadcrumbs: @breadcrumbs))

    assert_selector 'script[type="application/ld+json"]', visible: false
    json = JSON.parse(page.find('script[type="application/ld+json"]', visible: false).text(:all))
    assert_equal "https://schema.org", json["@context"]
    assert_equal "WebSite", json["@graph"].first["@type"]

    breadcrumb_data = json["@graph"].find { |item| item["@type"] == "BreadcrumbList" }
    assert_nil breadcrumb_data
  end
end
