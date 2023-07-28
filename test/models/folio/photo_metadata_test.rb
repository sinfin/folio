# frozen_string_literal: true

require "test_helper"

module Folio
  class PhotoMetadataTest < ActiveSupport::TestCase
    test "load exif and iptc metadata" do
      image = ::Folio::File::Image.new
      image.file = Rails.root.join("..", "fixtures", "folio", "photos", "night.jpg")
      image.save!

      assert_not_nil image.file_metadata
      assert_equal image.file_metadata["Keywords"], ["city", "light", "night", "prague"]
    end

    test "load metadata from different file types" do
      photo_dir = Rails.root.join("..", "fixtures", "folio", "photos")
      Dir.glob("#{photo_dir}/**/*").grep(/\.[jpg|JPG|tiff|TIFF]/).each do |photo|
        image = ::Folio::File::Image.new
        image.file = ::File.new(photo)
        image.save!

        # puts photo
        # puts image.file_metadata
        # puts '===='

        # Just for check correct execution
        image.title
        image.caption
        image.keywords
        image.geo_location

        assert_not_nil image.file_metadata
      end
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
#  thumbnail_sizes :text             default("--- {}\n")
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
