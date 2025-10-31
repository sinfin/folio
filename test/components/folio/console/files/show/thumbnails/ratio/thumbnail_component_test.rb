# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::Show::Thumbnails::Ratio::ThumbnailComponentTest < Folio::Console::ComponentTest
  def test_render
    thumbnail = { uid: "foo/bar/baz.jpg", signature: "123456", url: "https://a/b/c/d.jpg", width: 250, height: 167, quality: 82, x: nil, y: nil, private: false, gravity: nil, webp_uid: "https://a/b/c/d.webp", webp_url: "https://a/b/c/d.webp", webp_signature: "654321" }

    render_inline(Folio::Console::Files::Show::Thumbnails::Ratio::ThumbnailComponent.new(thumbnail:,
                                                                                         thumbnail_size_key: "250x167#",
                                                                                         file: create(:folio_file_image)))

    assert_selector(".f-c-files-show-thumbnails-ratio-thumbnail")
  end
end
