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
      240x140# 673x394# 708x421# 743x442# 975x568#
      800x450#
      2560x2048>
    ].sort

    result = Folio::Console::Files::Show::ThumbnailsComponent.group_thumbnail_size_keys(keys)
    crop = result["crop"]

    # all square sizes have the exact same ratio 1.0 -> one bucket labelled 1:1
    assert_equal %w[60x60# 70x70# 100x100# 120x120# 140x140# 200x200# 527x527# 648x648# 1054x1054# 1296x1296#].sort,
                 crop["1:1"].sort

    # 3:2 and 37:24 are now SEPARATE (2.8 % apart > 0.02 tolerance)
    assert_equal %w[120x80# 240x160# 480x320#].sort, crop["3:2"].sort
    assert_equal %w[370x240# 740x480#].sort, crop["37:24"].sort

    # 2:1 and 4:1 are separate
    assert_equal %w[200x100#], crop["2:1"]
    assert_equal %w[400x100#], crop["4:1"]

    # near-1.7 cluster collapses into ONE bucket labelled by the cleanest member (12:7)
    assert_equal %w[240x140# 673x394# 708x421# 743x442# 975x568#].sort, crop["12:7"].sort

    # 16:9 stays separate from the near-1.7 cluster (3.6 % from 12:7)
    assert_equal %w[800x450#], crop["16:9"]

    # regular unchanged
    assert_equal %w[250x250 500x500 400x700 800x1400 120x x240 2560x2048>], result["regular"]["regular"]
  end

  test "group_thumbnail_size_keys clusters the real-world set into 10 buckets" do
    keys = %w[
      1000x540# 1200x630# 120x80# 1346x788# 1390x784# 1390x928# 140x93# 1416x796# 1416x842#
      1486x832# 1486x834# 1486x884# 1488x838# 160x160# 1950x1098# 1950x1136# 200x150# 200x200#
      240x140# 240x160# 240x240# 260x145# 260x200# 280x186# 300x175# 306x208# 348x196# 370x240#
      400x400# 424x243# 424x283# 436x238# 480x280# 480x320# 480x480# 488x350# 500x270# 520x290#
      520x400# 540x360# 600x350# 612x416# 673x394# 695x392# 695x464# 696x392# 708x398# 708x421#
      740x480# 743x416# 743x417# 743x442# 744x419# 800x450# 80x80# 848x486# 848x566# 870x580#
      872x476# 975x549# 975x568# 976x700#
      250x250 400x700 500x500 800x1400 2560x2048>
    ]

    crop = Folio::Console::Files::Show::ThumbnailsComponent.group_thumbnail_size_keys(keys)["crop"]

    assert_equal %w[1:1 3:2 4:3 12:7 13:10 16:9 37:24 40:21 50:27 244:175].sort, crop.keys.sort

    assert_includes crop["3:2"], "140x93#"          # near-3:2 merges despite a far bucket anchor
    assert_includes crop["3:2"], "306x208#"
    assert_equal %w[370x240# 740x480#].sort, crop["37:24"].sort
    assert_includes crop["50:27"], "436x238#"
    assert_equal keys.count { |k| k.end_with?("#") }, crop.values.flatten.size
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
