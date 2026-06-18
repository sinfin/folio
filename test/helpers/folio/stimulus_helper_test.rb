# frozen_string_literal: true

require "test_helper"

class Folio::StimulusHelperTest < ActionView::TestCase
  include Folio::StimulusHelper

  def setup
    @file = create(:folio_file_image,
                   author: "File Author",
                   attribution_source: "File Attribution",
                   description: "File description")
  end

  def parse_photoswipe(result)
    JSON.parse(result["photoswipe"])
  end

  test "stimulus_lightbox_item with a standalone file uses file-level metadata" do
    photoswipe = parse_photoswipe(stimulus_lightbox_item(@file))

    assert_equal "File description", photoswipe["caption"]
    assert_equal "File Author", photoswipe["author"]
  end

  test "stimulus_lightbox_item with a placement WITHOUT description override falls back to file description" do
    @file.update!(attribution_source: nil)
    placement = create(:folio_file_placement_cover, file: @file, description: nil)

    photoswipe = parse_photoswipe(stimulus_lightbox_item(placement))

    assert_equal "File description", photoswipe["caption"]
    assert_equal "File Author", photoswipe["author"]
  end

  test "stimulus_lightbox_item with a placement WITH description override uses the override" do
    placement = create(:folio_file_placement_cover,
                       file: @file,
                       description: "Placement-specific description")

    photoswipe = parse_photoswipe(stimulus_lightbox_item(placement))

    assert_equal "Placement-specific description", photoswipe["caption"]
  end

  test "stimulus_lightbox_item with a placement prefers file.attribution_source over file.author" do
    placement = create(:folio_file_placement_cover, file: @file)

    photoswipe = parse_photoswipe(stimulus_lightbox_item(placement))

    assert_equal "File Attribution", photoswipe["author"]
  end

  test "stimulus_lightbox_item with a placement falls back to file.author when attribution_source is blank" do
    @file.update!(attribution_source: nil)
    placement = create(:folio_file_placement_cover, file: @file)

    photoswipe = parse_photoswipe(stimulus_lightbox_item(placement))

    assert_equal "File Author", photoswipe["author"]
  end

  test "stimulus_lightbox_item respects explicit title: and author: keyword overrides" do
    placement = create(:folio_file_placement_cover,
                       file: @file,
                       description: "Placement description")

    photoswipe = parse_photoswipe(stimulus_lightbox_item(placement,
                                                        title: "Forced caption",
                                                        author: "Forced author"))

    assert_equal "Forced caption", photoswipe["caption"]
    assert_equal "Forced author", photoswipe["author"]
  end
end
