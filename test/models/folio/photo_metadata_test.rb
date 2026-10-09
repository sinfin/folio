# frozen_string_literal: true

require "test_helper"

module Folio
  class PhotoMetadataTest < ActiveSupport::TestCase
    test "load exif and iptc metadata" do
      image = ::Folio::File::Image.new(site: get_any_site)
      image.file = Rails.root.join("..", "fixtures", "folio", "photos", "night.jpg")
      image.save!

      assert_not_nil image.file_metadata
      assert_equal ["city", "light", "night", "prague"], image.mapped_metadata[:keywords]
    end

    test "load metadata from different file types" do
      photo_dir = Rails.root.join("..", "fixtures", "folio", "photos")
      Dir.glob("#{photo_dir}/**/*").grep(/\.[jpg|JPG|tiff|TIFF]/).each do |photo|
        image = ::Folio::File::Image.new(site: get_any_site)
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
