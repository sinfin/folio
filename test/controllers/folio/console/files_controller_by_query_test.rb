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

  test "by_query works for document files" do
    get url_for([:console, Folio::File::Document]), params: { by_query: "Pardubice" }
    assert_response :success
  end
end
