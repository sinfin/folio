# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::ImageComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(Folio::Console::Ui::ImageComponent.new(placement: create(:folio_file_placement_cover),
                                                         size: "100x100"))

    assert_selector(".f-c-ui-image")
  end

  def test_placeholder_urls_skip_srcset
    # Test hash-based placement with placeholder URLs (using the format from temporary_url)
    placement_hash = {
      normal: "https://doader.com/100x100?image=123&size=100x100",
      retina: "https://doader.com/200x200?image=123&size=200x200",
      webp_normal: "https://doader.com/100x100?image=123&size=100x100.webp",
      webp_retina: "https://doader.com/200x200?image=123&size=200x200.webp"
    }

    render_inline(Folio::Console::Ui::ImageComponent.new(placement: placement_hash, size: "100x100"))

    # Should not have srcset attribute when URLs contain doader.com
    assert_no_selector("img[srcset]")

    # Should still have src attribute
    assert_selector("img[src='https://doader.com/100x100?image=123&size=100x100']")
  end

  def test_ready_urls_include_srcset
    # Test hash-based placement with ready URLs
    placement_hash = {
      normal: "https://example.com/image_100x100.jpg",
      retina: "https://example.com/image_200x200.jpg",
      webp_normal: "https://example.com/image_100x100.webp",
      webp_retina: "https://example.com/image_200x200.webp"
    }

    render_inline(Folio::Console::Ui::ImageComponent.new(placement: placement_hash, size: "100x100"))

    # Should have srcset when URLs are ready
    assert_selector("img[srcset='https://example.com/image_100x100.jpg 1x, https://example.com/image_200x200.jpg 2x']")
  end

  def test_mixed_placeholder_and_ready_urls
    # Test when only retina URL is placeholder
    placement_hash = {
      normal: "https://example.com/image_100x100.jpg",
      retina: "https://doader.com/200x200?image=789&size=200x200",
      webp_normal: "https://example.com/image_100x100.webp",
      webp_retina: "https://doader.com/200x200?image=789&size=200x200.webp"
    }

    render_inline(Folio::Console::Ui::ImageComponent.new(placement: placement_hash, size: "100x100"))

    # Should not have srcset when retina URL is placeholder
    assert_no_selector("img[srcset]")

    # Should still have src attribute
    assert_selector("img[src='https://example.com/image_100x100.jpg']")
  end

  def test_partial_webp_readiness
    # Test when only webp_normal is ready but webp_retina is placeholder
    placement_hash = {
      normal: "https://example.com/image_100x100.jpg",
      retina: "https://example.com/image_200x200.jpg",
      webp_normal: "https://example.com/image_100x100.webp",
      webp_retina: "https://doader.com/200x200?image=101112&size=200x200.webp"
    }

    render_inline(Folio::Console::Ui::ImageComponent.new(placement: placement_hash, size: "100x100"))

    # Should have regular srcset since normal and retina are ready
    assert_selector("img[srcset='https://example.com/image_100x100.jpg 1x, https://example.com/image_200x200.jpg 2x']")
  end
end
