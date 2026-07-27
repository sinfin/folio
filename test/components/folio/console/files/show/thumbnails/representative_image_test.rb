# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::Show::Thumbnails::RepresentativeImageTest < ActiveSupport::TestCase
  test "returns the largest size key by area" do
    mod = Folio::Console::Files::Show::Thumbnails::RepresentativeImage
    assert_equal "800x400#", mod.representative_thumbnail_size_key(%w[200x100# 800x400# 400x200#])
  end

  test "prefers the largest size matching the requested ratio" do
    mod = Folio::Console::Files::Show::Thumbnails::RepresentativeImage
    keys = %w[400x300# 800x600# 1200x800#]

    assert_equal "800x600#", mod.representative_thumbnail_size_key(keys, preferred_ratio: "4:3")
  end

  test "falls back to the largest size when no key matches the requested ratio" do
    mod = Folio::Console::Files::Show::Thumbnails::RepresentativeImage
    keys = %w[400x250# 800x450#]

    assert_equal "800x450#", mod.representative_thumbnail_size_key(keys, preferred_ratio: "4:3")
  end

  test "falls back when the exact-ratio thumbnail is unavailable" do
    mod = Folio::Console::Files::Show::Thumbnails::RepresentativeImage
    file = Struct.new(:thumbnail_sizes).new({
      "400x300#" => {},
      "480x320#" => { url: "https://example.com/larger.jpg" },
    })

    Folio::S3.stub(:cdn_url_rewrite, -> (url) { url }) do
      assert_equal "https://example.com/larger.jpg",
                   mod.representative_url(file:, keys: file.thumbnail_sizes.keys, preferred_ratio: "4:3")
    end
  end
end
