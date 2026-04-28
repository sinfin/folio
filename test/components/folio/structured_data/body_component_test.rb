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

  test "render article structured data with image as ImageObject" do
    create_and_host_site
    article = create(:dummy_blog_article, published_at: Time.current)
    image = create(:folio_file_image)
    create(:folio_file_placement_cover, file: image, placement: article)
    article.reload

    render_inline(Folio::StructuredData::BodyComponent.new(record: article, breadcrumbs: []))

    json = JSON.parse(page.find('script[type="application/ld+json"]', visible: false).text(:all))
    article_data = json["@graph"].find { |item| item["@type"] == "Article" }

    assert_not_nil article_data
    assert_equal "ImageObject", article_data["image"]["@type"]
    assert article_data["image"]["url"].present?
  end

  test "render article image creditText combines author and attribution_source" do
    create_and_host_site
    article = create(:dummy_blog_article, published_at: Time.current)
    image = create(:folio_file_image, author: "Jan Novák", attribution_source: "ČTK")
    create(:folio_file_placement_cover, file: image, placement: article)
    article.reload

    render_inline(Folio::StructuredData::BodyComponent.new(record: article, breadcrumbs: []))

    json = JSON.parse(page.find('script[type="application/ld+json"]', visible: false).text(:all))
    article_data = json["@graph"].find { |item| item["@type"] == "Article" }

    assert_equal "Jan Novák / ČTK", article_data["image"]["creditText"]
  end

  test "render article image creditText contains only attribution_source when author is blank" do
    create_and_host_site
    article = create(:dummy_blog_article, published_at: Time.current)
    image = create(:folio_file_image, author: nil, attribution_source: "Reuters")
    create(:folio_file_placement_cover, file: image, placement: article)
    article.reload

    render_inline(Folio::StructuredData::BodyComponent.new(record: article, breadcrumbs: []))

    json = JSON.parse(page.find('script[type="application/ld+json"]', visible: false).text(:all))
    article_data = json["@graph"].find { |item| item["@type"] == "Article" }

    assert_equal "Reuters", article_data["image"]["creditText"]
  end

  test "render article image creditText contains only author when attribution_source is blank" do
    create_and_host_site
    article = create(:dummy_blog_article, published_at: Time.current)
    image = create(:folio_file_image, author: "Petr Novák", attribution_source: nil)
    create(:folio_file_placement_cover, file: image, placement: article)
    article.reload

    render_inline(Folio::StructuredData::BodyComponent.new(record: article, breadcrumbs: []))

    json = JSON.parse(page.find('script[type="application/ld+json"]', visible: false).text(:all))
    article_data = json["@graph"].find { |item| item["@type"] == "Article" }

    assert_equal "Petr Novák", article_data["image"]["creditText"]
  end

  test "render article image has no creditText when cover has neither author nor attribution_source" do
    create_and_host_site
    article = create(:dummy_blog_article, published_at: Time.current)
    image = create(:folio_file_image, author: nil, attribution_source: nil)
    create(:folio_file_placement_cover, file: image, placement: article)
    article.reload

    render_inline(Folio::StructuredData::BodyComponent.new(record: article, breadcrumbs: []))

    json = JSON.parse(page.find('script[type="application/ld+json"]', visible: false).text(:all))
    article_data = json["@graph"].find { |item| item["@type"] == "Article" }

    assert_not article_data["image"].key?("creditText")
  end

  test "render article structured data has no image when article has no cover" do
    create_and_host_site
    article = create(:dummy_blog_article, published_at: Time.current)

    render_inline(Folio::StructuredData::BodyComponent.new(record: article, breadcrumbs: []))

    json = JSON.parse(page.find('script[type="application/ld+json"]', visible: false).text(:all))
    article_data = json["@graph"].find { |item| item["@type"] == "Article" }

    assert_not_nil article_data
    assert_nil article_data["image"]
  end
end
