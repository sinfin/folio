# frozen_string_literal: true

require "test_helper"

class Folio::ImageTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "additional data - white" do
    white = create(:folio_image)
    assert_nil(white.additional_data)

    perform_enqueued_jobs do
      white = create(:folio_image)
      white.reload
      assert_equal("#FFFFFF", white.additional_data["dominant_color"])
      assert_equal(false, white.additional_data["dark"])
    end
  end

  test "additional data - black" do
    black = create(:folio_image, :black)
    assert_nil(black.additional_data)

    perform_enqueued_jobs do
      black = create(:folio_image, :black)
      black.reload
      assert_equal("#000000", black.additional_data["dominant_color"])
      assert_equal(true, black.additional_data["dark"])
    end
  end
end
