# frozen_string_literal: true

require "test_helper"

class Folio::GenerateThumbnailJobTest < ActiveJob::TestCase
  test "thumb" do
    image = create(:folio_file_image, additional_data: { "generate_thumbnails_in_test" => true })

    assert_nil image.thumbnail_sizes["100x100#"]

    perform_enqueued_jobs do
      image.thumb("100x100#")
    end

    image.reload

    assert_match(/test\.jpg\Z/, image.thumbnail_sizes["100x100#"][:url])
    assert_match(/test\.webp\Z/, image.thumbnail_sizes["100x100#"][:webp_url])
  end

  test "uses fallback image when file is missing" do
    skip "Test only runs with local file datastore to avoid S3 access" unless Dragonfly.app.datastore.is_a?(Dragonfly::FileDataStore)

    image = create(:folio_file_image, additional_data: { "generate_thumbnails_in_test" => true })
    file_uid = image.file_uid

    # Delete the file from local datastore to simulate missing file
    Dragonfly.app.datastore.destroy(file_uid) if file_uid

    perform_enqueued_jobs do
      result = image.thumb("100x100#")
      assert_not_nil result
      assert_not_nil result.url
    end

    image.reload

    # Verify thumbnail was generated successfully despite missing file
    assert_not_nil image.thumbnail_sizes["100x100#"]
    assert_not_nil image.thumbnail_sizes["100x100#"][:uid]
    assert_not_nil image.thumbnail_sizes["100x100#"][:url]
  end

  test "broadcasts the generated size and crop coordinates" do
    image = create(:folio_file_image, additional_data: { "generate_thumbnails_in_test" => true })
    messages = []

    MessageBus.stub(:publish, -> (_channel, message, **) { messages << JSON.parse(message) }) do
      Folio::GenerateThumbnailJob.perform_now(image,
                                              "100x100#",
                                              Folio::Thumbnails::DEFAULT_QUALITY,
                                              force: true,
                                              x: 0.2,
                                              y: 0.3)
    end

    message = messages.find { |item| item["type"] == "Folio::GenerateThumbnailJob" }

    assert_equal image.id, message.dig("data", "id")
    assert_equal "100x100#", message.dig("data", "size")
    assert_equal 0.2, message.dig("data", "thumb", "x")
    assert_equal 0.3, message.dig("data", "thumb", "y")
    assert_predicate message.dig("data", "url"), :present?
  end
end
