# frozen_string_literal: true

require "test_helper"

class Folio::Console::File::ImagesUsageRecordTest < Folio::Console::BaseControllerTest
  def setup
    super
    @image = create(:folio_file_image, site: @site, attribution_max_usage_count: 1)
    @article = create(:dummy_blog_article, site: @site, published: true)
    @article.create_cover_placement!(file: @image)
    assert @image.reload.usage_limit_exceeded?(site: @site)
  end

  test "picker allows a file the published usage record already uses" do
    get url_for([:index_for_picker, :console, Folio::File::Image, usage_record: usage_record_sgid])

    assert_response :success
    assert_selectable
    assert_select "#{image_selector}.f-file-list-file--unmet-requirements", count: 0
  end

  test "modal allows a file the published usage record already uses" do
    get url_for([:index_for_modal, :console, Folio::File::Image, usage_record: usage_record_sgid])

    assert_response :success
    assert_selectable
  end

  test "an atom picker can reuse the article cover with the context from its editor" do
    get url_for([:edit, :console, @article])

    assert_response :success
    data = JSON.parse(Nokogiri::HTML(response.body).at_css(".f-c-atoms")["data-atoms"])

    get url_for([:index_for_modal, :console, Folio::File::Image]),
        params: { usage_record: data["usageRecord"], by_query: @image.file_name }

    assert_response :success
    assert_selectable
  end

  test "picker allows a file the usage record uses in an atom" do
    @article.cover_placement.destroy!
    create_atom(Dummy::Atom::Contents::ImageAndText, placement: @article, cover: @image, content: "content")
    assert @image.reload.usage_limit_exceeded?(site: @site)

    get url_for([:index_for_picker, :console, Folio::File::Image, usage_record: usage_record_sgid])

    assert_response :success
    assert_selectable
  end

  test "picker blocks an exhausted file without a usage record" do
    get url_for([:index_for_picker, :console, Folio::File::Image])

    assert_response :success
    assert_selectable(false)
  end

  test "picker blocks an exhausted file for another usage record" do
    other_article = create(:dummy_blog_article, site: @site, published: true)

    get url_for([:index_for_picker, :console, Folio::File::Image, usage_record: usage_record_sgid(other_article)])

    assert_response :success
    assert_selectable(false)
  end

  test "picker blocks an exhausted file for an unpublished usage record" do
    @article.update_column(:published, false)

    get url_for([:index_for_picker, :console, Folio::File::Image, usage_record: usage_record_sgid])

    assert_response :success
    assert_selectable(false)
  end

  test "picker ignores a tampered usage record" do
    get url_for([:index_for_picker, :console, Folio::File::Image, usage_record: "#{usage_record_sgid}x"])

    assert_response :success
    assert_selectable(false)
  end

  test "file index keeps the usage limit warning with a usage record" do
    get url_for([:console, Folio::File::Image, usage_record: usage_record_sgid])

    assert_response :success
    assert_select "#{image_selector}.f-file-list-file--unmet-requirements"
  end

  test "file index keeps exhausted files in the unusable filter despite a usage record" do
    get url_for([:console, Folio::File::Image,
                 usage_record: usage_record_sgid, by_usage_constraints: "unusable"])

    assert_response :success
    assert_select image_selector
  end

  test "file index usable filter still excludes exhausted files despite a usage record" do
    get url_for([:console, Folio::File::Image,
                 usage_record: usage_record_sgid, by_usage_constraints: "usable"])

    assert_response :success
    assert_select image_selector, count: 0
  end

  test "usable filter includes a file the usage record already uses" do
    other_image = create(:folio_file_image, site: @site, attribution_max_usage_count: 1)
    create(:dummy_blog_article, site: @site, published: true).create_cover_placement!(file: other_image)

    get url_for([:index_for_picker, :console, Folio::File::Image,
                 usage_record: usage_record_sgid, by_usage_constraints: "usable"])

    assert_response :success
    assert_select image_selector
    assert_select image_selector(other_image), count: 0
  end

  test "unusable filter excludes a file the usage record already uses" do
    get url_for([:index_for_picker, :console, Folio::File::Image,
                 usage_record: usage_record_sgid, by_usage_constraints: "unusable"])

    assert_response :success
    assert_select image_selector, count: 0
  end

  test "picker keeps the usage record in filters, cancel link and pagination" do
    get url_for([:index_for_picker, :console, Folio::File::Image,
                 usage_record: usage_record_sgid, by_usage_constraints: "usable"])

    assert_response :success
    assert_select "input[type='hidden'][name='f-c-ui-index-filters[usage_record]'][value='#{usage_record_sgid}']"
    assert_select ".f-c-ui-index-filters__cancel" do |links|
      assert_equal usage_record_sgid, query_param(links.first["href"], "usage_record")
    end
    assert_select "[data-f-c-ui-pagy-reload-url-value]" do |elements|
      reload_url = elements.first["data-f-c-ui-pagy-reload-url-value"]
      assert_equal usage_record_sgid, query_param(reload_url, "usage_record")
      assert_equal "usable", query_param(reload_url, "by_usage_constraints")
    end
  end

  test "API pagination counts files the usage record already uses as usable" do
    get url_for([:pagination, :console, :api, Folio::File::Image,
                 usage_record: usage_record_sgid,
                 by_usage_constraints: "usable",
                 request_path: url_for([:index_for_picker, :console, Folio::File::Image, only_path: true])]),
        as: :json

    assert_response :success
    html = Nokogiri::HTML.fragment(response.parsed_body.fetch("data"))
    reload_url = html.at_css("[data-f-c-ui-pagy-reload-url-value]")["data-f-c-ui-pagy-reload-url-value"]
    assert_equal usage_record_sgid, query_param(reload_url, "usage_record")
    assert_equal 1, controller.instance_variable_get(:@pagy).count
  end

  test "API pagination of the file index retains the ordinary usage filter" do
    get url_for([:pagination, :console, :api, Folio::File::Image,
                 usage_record: usage_record_sgid,
                 by_usage_constraints: "unusable",
                 request_path: url_for([:console, Folio::File::Image, only_path: true])]),
        as: :json

    assert_response :success
    assert_equal 1, controller.instance_variable_get(:@pagy).count
  end

  test "single file reload keeps a reused file selectable" do
    get file_list_file_folio_api_s3_path(file_type: @image.class.name,
                                         file_id: @image.id,
                                         primary_action: "index_for_picker",
                                         usage_record: usage_record_sgid),
        as: :json

    assert_response :success
    html = Nokogiri::HTML.fragment(response.parsed_body.fetch("data"))
    assert html.at_css("[data-action*='click->f-file-list-file#primaryAction']")
    assert_equal usage_record_sgid, html.at_css(".f-file-list-file")["data-f-file-list-file-usage-record-value"]
  end

  private
    def usage_record_sgid(record = @article)
      Folio::File::UsageRecord.sgid_for(record)
    end

    def image_selector(image = @image)
      ".f-file-list-file[data-f-file-list-file-id-value='#{image.id}']"
    end

    def assert_selectable(selectable = true)
      assert_select image_selector do
        assert_select "[data-action*='click->f-file-list-file#primaryAction']", selectable ? { minimum: 1 } : { count: 0 }
      end
    end

    def query_param(url, key)
      Rack::Utils.parse_nested_query(URI.parse(url).query)[key]
    end
end
