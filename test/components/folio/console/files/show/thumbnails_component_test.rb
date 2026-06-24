# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::Show::ThumbnailsComponentTest < Folio::Console::ComponentTest
  test "group_thumbnail_size_keys" do
    keys = %w[
      120x x240
      400x700 800x1400
      250x250 500x500
      60x60# 70x70# 100x100# 200x200# 120x120# 140x140# 648x648# 1296x1296# 527x527# 1054x1054#
      120x80# 240x160# 480x320#
      370x240# 740x480#
      200x100# 400x100#
      673x394# 708x421# 743x442# 975x568#
      800x450#
      2560x2048>
    ].sort

    result = Folio::Console::Files::Show::ThumbnailsComponent.group_thumbnail_size_keys(keys)
    crop = result["crop"]

    # 1:1 cluster
    assert_equal %w[60x60# 70x70# 100x100# 120x120# 140x140# 200x200# 527x527# 648x648# 1054x1054# 1296x1296#].sort,
                 crop["1:1"].sort

    # ~1.5 cluster: 3:2 (120x80/240x160/480x320) + 37:24 (370x240/740x480) merged, label "3:2" (cleanest)
    assert_equal %w[120x80# 240x160# 370x240# 480x320# 740x480#].sort, crop["3:2"].sort

    # 2:1 and 4:1 are separate
    assert_equal %w[200x100#], crop["2:1"]
    assert_equal %w[400x100#], crop["4:1"]

    # ~1.7 card/hero cluster: 4 near-duplicates collapse into ONE bucket
    near17 = crop.select { |_label, ks| (ks & %w[673x394# 708x421# 743x442# 975x568#]).any? }
    assert_equal 1, near17.size, "near-1.7 sizes must collapse into ONE bucket, got: #{near17.keys.inspect}"
    assert_equal %w[673x394# 708x421# 743x442# 975x568#].sort, near17.values.flatten.sort

    # 16:9 (800x450#) stays separate from ~1.7 cluster
    assert crop.key?("16:9"), "16:9 should be its own bucket"
    assert_equal %w[800x450#], crop["16:9"]

    # regular unchanged
    assert_equal %w[250x250 500x500 400x700 800x1400 120x x240 2560x2048>], result["regular"]["regular"]
  end

  test "render" do
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        file = create(:folio_file_image)

        render_inline(Folio::Console::Files::Show::ThumbnailsComponent.new(file:))

        assert_selector(".f-c-files-show-thumbnails")
      end
    end
  end
end
