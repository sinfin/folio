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

  test "render article image creditText deduplicates matching author and attribution_source" do
    create_and_host_site
    article = create(:dummy_blog_article, published_at: Time.current)
    image = create(:folio_file_image, author: "Reuters", attribution_source: "Reuters")
    create(:folio_file_placement_cover, file: image, placement: article)
    article.reload

    render_inline(Folio::StructuredData::BodyComponent.new(record: article, breadcrumbs: []))

    json = JSON.parse(page.find('script[type="application/ld+json"]', visible: false).text(:all))
    article_data = json["@graph"].find { |item| item["@type"] == "Article" }

    assert_equal "Reuters", article_data["image"]["creditText"]
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

  test "render article video structured data from provider metadata without original file URL" do
    create_and_host_site
    article = create(:dummy_blog_article,
                     title: "Article with video",
                     perex: "Article perex",
                     published_at: Time.current)
    video = create(:folio_file_video,
                   headline: "Provider video",
                   description: "Provider description",
                   file_uid: "private/original.mp4",
                   remote_services_data: {
                     "service" => "cloudflare_stream",
                     "uid" => "stream-1",
                     "ready_to_stream" => true,
                     "thumbnail" => "https://customer-code.cloudflarestream.com/stream-1/thumbnails/thumbnail.jpg",
                     "playback" => {
                       "hls" => "https://customer-code.cloudflarestream.com/stream-1/manifest/video.m3u8",
                     },
                   })
    Folio::FilePlacement::VideoCover.create!(file: video, placement: article)
    article.reload

    render_inline(Folio::StructuredData::BodyComponent.new(record: article, breadcrumbs: []))

    json = JSON.parse(page.find('script[type="application/ld+json"]', visible: false).text(:all))
    video_data = json["@graph"].find { |item| item["@type"] == "VideoObject" }

    assert_not_nil video_data
    assert_equal "Article with video", video_data["name"]
    assert_equal "Provider description", video_data["description"]
    assert_equal "https://customer-code.cloudflarestream.com/stream-1/thumbnails/thumbnail.jpg", video_data["thumbnailUrl"]
    assert_equal "https://customer-code.cloudflarestream.com/stream-1/iframe", video_data["embedUrl"]
    assert_nil video_data["contentUrl"]
    assert_not_includes video_data.to_json, "private/original.mp4"
  end

  test "render video record structured data from provider metadata" do
    create_and_host_site
    video = create(:folio_file_video,
                   headline: "Standalone video",
                   description: "Standalone description",
                   file_uid: "private/original.mp4",
                   remote_services_data: {
                     "service" => "cloudflare_stream",
                     "uid" => "stream-1",
                     "ready_to_stream" => true,
                     "thumbnail" => "https://customer-code.cloudflarestream.com/stream-1/thumbnails/thumbnail.jpg",
                     "playback" => {
                       "hls" => "https://customer-code.cloudflarestream.com/stream-1/manifest/video.m3u8",
                     },
                   })

    render_inline(Folio::StructuredData::BodyComponent.new(record: video, breadcrumbs: []))

    json = JSON.parse(page.find('script[type="application/ld+json"]', visible: false).text(:all))
    video_data = json["@graph"].find { |item| item["@type"] == "VideoObject" }

    assert_not_nil video_data
    assert_equal "Standalone video", video_data["name"]
    assert_equal "Standalone description", video_data["description"]
    assert_equal "https://customer-code.cloudflarestream.com/stream-1/iframe", video_data["embedUrl"]
    assert_nil video_data["contentUrl"]
    assert_not_includes video_data.to_json, "private/original.mp4"
  end
end
