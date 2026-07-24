# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::Show::Thumbnails::RepresentativeImageTest < ActiveSupport::TestCase
  test "returns the largest size key by area" do
    mod = Folio::Console::Files::Show::Thumbnails::RepresentativeImage
    assert_equal "800x400#", mod.representative_thumbnail_size_key(%w[200x100# 800x400# 400x200#])
  end
end
