# frozen_string_literal: true

require "test_helper"

module Folio
  class ImageeTest < ActiveSupport::TestCase
    test "additional data - white" do
      white = create(:folio_image)

      assert_equal("#FFFFFF", white.additional_data["dominant_color"])
      assert_equal(false, white.additional_data["dark"])
    end

    test "additional data - black" do
      black = create(:folio_image, :black)

      assert_equal("#000000", black.additional_data["dominant_color"])
      assert_equal(true, black.additional_data["dark"])
    end
  end
end

# == Schema Information
#
# Table name: folio_files
#
#  id              :integer          not null, primary key
#  file_uid        :string
#  file_name       :string
#  type            :string
#  thumbnail_sizes :text             default({})
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  file_width      :integer
#  file_height     :integer
#  file_size       :integer
#  mime_type       :string(255)
#  additional_data :json
#
# Indexes
#
#  index_folio_files_on_type  (type)
#
