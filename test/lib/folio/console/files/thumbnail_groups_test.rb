# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::ThumbnailGroupsTest < ActiveSupport::TestCase
  test ".call groups detailed thumbnail sizes" do
    keys = %w[
      120x x240
      400x700 800x1400
      250x250 500x500
      40x40# 40x40#c 60x60# 70x70# 100x100# 200x200# 120x120# 140x140# 648x648# 1296x1296# 527x527# 1054x1054#
      120x80# 240x160# 480x320#
      370x240# 740x480#
      200x100# 400x100#
      240x140# 673x394# 708x421# 743x442# 975x568#
      800x450#
      2560x2048>
    ].sort
    file = image_with_sizes(keys)

    result = described_class.call(file:, site: file.site)
    crop = result["crop"].index_by { |group| group["ratio"] }

    assert_equal %w[40x40# 40x40#c 60x60# 70x70# 100x100# 120x120# 140x140# 200x200# 527x527# 648x648# 1054x1054# 1296x1296#].sort,
                 crop["1:1"]["sizes"].sort
    assert_equal "1×1", crop["1:1"]["ratio_label"]
    assert_nil crop["1:1"]["label"]
    assert_equal %w[120x80# 240x160# 480x320#].sort, crop["3:2"]["sizes"].sort
    assert_equal %w[370x240# 740x480#].sort, crop["37:24"]["sizes"].sort
    assert_equal %w[200x100#], crop["2:1"]["sizes"]
    assert_equal %w[400x100#], crop["4:1"]["sizes"]
    assert_equal %w[240x140# 673x394# 708x421# 743x442# 975x568#].sort, crop["12:7"]["sizes"].sort
    assert_equal %w[800x450#], crop["16:9"]["sizes"]
    assert_equal [{ "ratio" => "regular", "ratio_label" => "regular", "label" => nil,
                    "sizes" => %w[250x250 500x500 400x700 800x1400 120x x240 2560x2048>] }],
                 result["regular"]
  end

  test ".call clusters the real-world sizes into ten detailed groups" do
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
    file = image_with_sizes(keys)

    crop = described_class.call(file:, site: file.site)["crop"].index_by { |group| group["ratio"] }

    assert_equal %w[1:1 3:2 4:3 12:7 13:10 16:9 37:24 40:21 50:27 244:175].sort, crop.keys.sort
    assert_includes crop["3:2"]["sizes"], "140x93#"
    assert_includes crop["3:2"]["sizes"], "306x208#"
    assert_equal %w[370x240# 740x480#].sort, crop["37:24"]["sizes"].sort
    assert_includes crop["50:27"]["sizes"], "436x238#"
    assert_equal keys.count { |key| key.end_with?("#") }, crop.values.sum { |group| group["sizes"].size }
  end

  test ".call reduces the real-world ratios to four main crop families" do
    ratios = %w[
      1:1 3:2 4:3 12:7 13:10 16:9 40:21 37:24 41:24 50:27 52:29 87:49 135:76 140:93
      162:95 153:104 159:103 218:119 244:175 325:183 354:199 424:243 424:283 673:394
      695:392 708:421 743:416 743:417 744:419 695:464 743:442 975:568
    ]
    file = image_with_sizes(ratios.map { |ratio| "#{ratio.tr(':', 'x')}#" })

    groups = described_class.call(file:, site: file.site)

    assert_equal %w[1:1 4:3 16:9 2:1], groups["main_crop"].pluck("ratio")
    assert_equal ratios.sort, groups["main_crop"].flat_map { |group| group["ratios"] }.sort
    assert_equal ratios.size, groups["main_crop"].sum { |group| group["sizes"].size }
  end

  test ".call keeps unusual ratios and uses reciprocal portrait families" do
    file = image_with_sizes(%w[400x100# 200x100# 100x200# 120x200# 300x400#])

    groups = described_class.call(file:, site: file.site)

    assert_equal %w[2:1 4:1 1:2 3:4 9:16].sort, groups["main_crop"].pluck("ratio").sort
  end

  test ".call allows main ratio mapping to be configured per site" do
    file = image_with_sizes(%w[200x120# 400x250#])
    calls = []
    main_ratio_proc = lambda do |ratio:, sizes:, site:|
      calls << { ratio:, sizes:, site: }
      "2:1"
    end

    Rails.application.config.stub(:folio_console_files_thumbnail_groups_main_ratio_proc, -> { main_ratio_proc }) do
      groups = described_class.call(file:, site: file.site)

      assert_equal ["2:1"], groups["main_crop"].pluck("ratio")
    end

    assert_equal %w[5:3 8:5], calls.pluck(:ratio)
    assert_equal file.site, calls.first.fetch(:site)
    assert_equal [%w[200x120#], %w[400x250#]], calls.pluck(:sizes)
  end

  test ".find distinguishes a main family from its detailed ratio" do
    file = image_with_sizes(%w[200x120# 400x250# 800x450#])

    main_group = described_class.find(file:, site: file.site, group_type: "main_crop", ratio: "16:9")
    detailed_group = described_class.find(file:, site: file.site, group_type: "crop", ratio: "16:9")

    assert_equal %w[200x120# 400x250# 800x450#], main_group.fetch("sizes")
    assert_equal %w[800x450#], detailed_group.fetch("sizes")
    assert_nil described_class.find(file:, site: file.site, group_type: "invalid", ratio: "16:9")
  end

  private
    def described_class
      Folio::Console::Files::ThumbnailGroups
    end

    def image_with_sizes(keys)
      create(:folio_file_image).tap do |file|
        file.update!(thumbnail_sizes: keys.index_with { { url: "https://example.com/thumbnail.jpg" } })
      end
    end
end
