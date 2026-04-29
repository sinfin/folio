# frozen_string_literal: true

require "test_helper"

class Folio::Console::FilesControllerByQueryTest < Folio::Console::BaseControllerTest
  test "by_query filter is available in index_filters" do
    get url_for([:console, Folio::File::Image])
    assert_response :success

    filters = @controller.send(:index_filters)
    assert_includes filters.keys, :by_query
  end

  test "index with by_query param returns success" do
    create(:folio_file_image, file_metadata: { "keywords" => ["Pardubice"] })

    get url_for([:console, Folio::File::Image]), params: { by_query: "Pardubice" }
    assert_response :success
  end

  test "index with empty by_query param returns success" do
    get url_for([:console, Folio::File::Image]), params: { by_query: "" }
    assert_response :success
  end

  test "by_query handles special characters without raising" do
    [
      "Pardubice-město",
      "'; DROP TABLE folio_files; --",
      "Pardubice%",
      "Pardubice_",
      "100%"
    ].each do |query|
      get url_for([:console, Folio::File::Image]), params: { by_query: query }
      assert_response :success, "Failed for query: #{query}"
    end
  end

  test "by_query works for video files" do
    get url_for([:console, Folio::File::Video]), params: { by_query: "Pardubice" }
    assert_response :success
  end

  test "image index with by_query sorts newest first" do
    created_at = Time.zone.parse("2026-04-29 12:00:00")
    older = create(:folio_file_image, site: @site, slug: "cs279-html-image-older", created_at: created_at - 1.hour)
    lower_id = create(:folio_file_image, site: @site, slug: "cs279-html-image-lower", created_at:)
    higher_id = create(:folio_file_image, site: @site, slug: "cs279-html-image-higher", created_at:)
    expected_ids = [higher_id.id, lower_id.id, older.id]

    get url_for([:console, Folio::File::Image]), params: { by_query: "cs279-html-image" }

    actual_ids = Nokogiri::HTML(response.body)
                         .css(".f-file-list-file")
                         .filter_map { |node| node["data-f-file-list-file-id-value"].presence&.to_i }
                         .select { |id| expected_ids.include?(id) }

    assert_response :success
    assert_equal expected_ids, actual_ids
  end

  test "video index with by_query sorts newest first" do
    created_at = Time.zone.parse("2026-04-29 13:00:00")
    older = create(:folio_file_video, site: @site, slug: "cs279-html-video-older", created_at: created_at - 1.hour)
    lower_id = create(:folio_file_video, site: @site, slug: "cs279-html-video-lower", created_at:)
    higher_id = create(:folio_file_video, site: @site, slug: "cs279-html-video-higher", created_at:)
    expected_ids = [higher_id.id, lower_id.id, older.id]

    get url_for([:console, Folio::File::Video]), params: { by_query: "cs279-html-video" }

    actual_ids = Nokogiri::HTML(response.body)
                         .css(".f-file-list-file")
                         .filter_map { |node| node["data-f-file-list-file-id-value"].presence&.to_i }
                         .select { |id| expected_ids.include?(id) }

    assert_response :success
    assert_equal expected_ids, actual_ids
  end

  test "image index sorts newest first when by_query is combined with another filter" do
    created_at = Time.zone.parse("2026-04-29 15:00:00")
    older = create(:folio_file_image,
                   site: @site,
                   slug: "cs279-combined-older",
                   created_at: created_at - 1.hour,
                   created_by_folio_user_id: @superadmin.id)
    newer = create(:folio_file_image,
                   site: @site,
                   slug: "cs279-combined-newer",
                   created_at:,
                   created_by_folio_user_id: @superadmin.id)
    expected_ids = [newer.id, older.id]

    get url_for([:console, Folio::File::Image]), params: {
      by_query: "cs279-combined",
      created_by_current_user: "1",
    }

    actual_ids = Nokogiri::HTML(response.body)
                         .css(".f-file-list-file")
                         .filter_map { |node| node["data-f-file-list-file-id-value"].presence&.to_i }
                         .select { |id| expected_ids.include?(id) }

    assert_response :success
    assert_equal expected_ids, actual_ids
  end

  test "by_query works for document files" do
    get url_for([:console, Folio::File::Document]), params: { by_query: "Pardubice" }
    assert_response :success
  end
end
