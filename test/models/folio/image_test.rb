# frozen_string_literal: true

require "test_helper"

class Folio::File::ImageTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "additional data - white" do
    image = create(:folio_file_image, file: Folio::Engine.root.join("test/fixtures/folio/test.gif"))
    assert_nil image.reload.additional_data

    [
      ["test-black.gif", "#000000", true],
      ["test-black.jpg", "#000000", true],
      ["test-black.png", "#000000", true],
      ["test.gif", "#FFFFFF", false],
      ["test.jpg", "#FFFFFF", false],
      ["test.png", "#FFFFFF", false],
    ].each do |file_name, dominant_color, dark|
      perform_enqueued_jobs do
        image = create(:folio_file_image, file: Folio::Engine.root.join("test/fixtures/folio", file_name))
        assert(image.reload.additional_data)
        assert_equal(dominant_color, image.additional_data["dominant_color"])
        assert_equal(dark, image.additional_data["dark"])
      end
    end
  end
end
