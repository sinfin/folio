# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::Show::ThumbnailsComponentTest < Folio::Console::ComponentTest
  test "group_thumbnail_size_keys" do
    keys = %w[
      120x
      x240

      400x700
      800x1400

      250x250
      500x500

      60x60#
      70x70#
      100x100#
      200x200#
      120x120#
      140x140#
      648x648#
      1296x1296#
      527x527#
      1054x1054#

      120x80#
      240x160#
      480x320#

      370x240#
      740x480#

      2560x2048>
    ].sort

    expected = {
      "regular" => {
        "1:1" => %w[250x250 500x500],
        "4:7" => %w[400x700 800x1400],
        "120:*" => %w[120x],
        "*:240" => %w[x240],
      },
      "crop" => {
        "1:1" => %w[
          60x60#
          70x70#
          100x100#
          120x120#
          140x140#
          200x200#
          527x527#
          648x648#
          1054x1054#
          1296x1296#
        ],
        "3:2" => %w[
          120x80#
          240x160#
          480x320#
        ],
        "37:24" => %w[
          370x240#
          740x480#
        ]
      },
      "shrink" => {
        "5:4" => %w[
          2560x2048>
        ]
      }
    }

    assert_equal expected, Folio::Console::Files::Show::ThumbnailsComponent.group_thumbnail_size_keys(keys)
  end

  test "render" do
    file = create(:folio_file_image)

    render_inline(Folio::Console::Files::Show::ThumbnailsComponent.new(file:))

    assert_selector(".f-c-files-show-thumbnails")
  end
end
