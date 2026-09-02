# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::Show::Thumbnails::ListGroupComponentTest < Folio::Console::ComponentTest
  def render_group(file:, ratio:, ratio_label:, label: nil, keys:)
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        render_inline(Folio::Console::Files::Show::Thumbnails::ListGroupComponent.new(file:,
                                                                                      ratio:,
                                                                                      ratio_label:,
                                                                                      label:,
                                                                                      thumbnail_size_keys: keys))
      end
    end
  end

  test "renders a detail crop preview with aligned thumbnails when its label is absent" do
    file = create(:folio_file_image)
    file.update_columns(file_width: 160, file_height: 90)
    file.update!(thumbnail_sizes: {
      "160x90#" => { url: "https://example.com/160x90.jpg" },
      "320x180#" => { url: "https://example.com/320x180.jpg" },
    })

    user = create(:folio_user, :superadmin)
    ability = Folio::Ability.new(user, get_any_site)

    Folio::Current.stub(:user, user) do
      Folio::Current.stub(:ability, ability) do
        render_group(file:, ratio: "16:9", ratio_label: "16×9", keys: %w[160x90# 320x180#])
      end
    end

    assert_selector('.f-c-files-show-thumbnails-list-group[data-ratio="16:9"]')
    assert_selector(".f-c-files-show-thumbnails-crop-edit__ratio-label", text: "16×9")
    assert_selector(".f-c-files-show-thumbnails-crop-edit__label")
    assert_selector(".f-c-files-show-thumbnails-list-group__preview .f-c-files-show-thumbnails-crop-edit--detail")
    assert_selector(".f-c-files-show-thumbnails-crop-edit__regenerate")
    assert_selector(".f-c-files-show-thumbnails-list-group__thumbs .f-c-files-show-thumbnails-ratio-thumbnail--detail", count: 2)
    assert_no_selector(".f-c-files-show-thumbnails-list-group__count")
    assert_no_selector(".f-c-files-show-thumbnails-list-group__representative-img")
  end

  test "renders configured secondary group label" do
    file = create(:folio_file_image)
    file.update!(thumbnail_sizes: { "160x90#" => { url: "https://example.com/160x90.jpg" } })

    render_group(file:, ratio: "16:9", ratio_label: "16×9", label: "Karta · Infobox", keys: %w[160x90#])

    assert_selector(".f-c-files-show-thumbnails-crop-edit__ratio-label", text: "16×9")
    assert_selector(".f-c-files-show-thumbnails-crop-edit__label", text: "Karta · Infobox")
  end

  test "regular group renders without a crop preview or count" do
    file = create(:folio_file_image)
    file.update!(thumbnail_sizes: { "250x250" => { url: "https://example.com/250x250.jpg" } })

    render_group(file:, ratio: "regular", ratio_label: "regular", keys: %w[250x250])

    assert_selector(".f-c-files-show-thumbnails-list-group__ratio-label", text: "Verze bez ořezu")
    assert_no_selector(".f-c-files-show-thumbnails-crop-edit__regenerate")
    assert_no_selector(".f-c-files-show-thumbnails-list-group__preview")
    assert_no_selector(".f-c-files-show-thumbnails-list-group__representative-img")
    assert_no_selector(".f-c-files-show-thumbnails-list-group__count")
  end
end
