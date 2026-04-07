# frozen_string_literal: true

require "test_helper"

class Folio::Console::FilePlacements::MultiPickerFieldsComponentTest < Folio::Console::ComponentTest
  def test_default_placement_attributes
    placement = create(:folio_file_placement_image_or_embed)
    view = vc_test_controller.view_context
    view.simple_form_for(placement, url: "/") do |g|
      render_inline(Folio::Console::FilePlacements::MultiPickerFields::PlacementComponent.new(
        g:,
        non_unique_file_id: false,
        placement_key: :file_placements,
        placement_attributes: Folio::Console::FilePlacements::MultiPickerFieldsComponent::DEFAULT_PLACEMENT_ATTRIBUTES,
      ))
    end

    assert_selector(".f-c-file-placements-multi-picker-fields-placement__field--title")
    assert_selector(".f-c-file-placements-multi-picker-fields-placement__field--description")
    assert_selector(".f-c-file-placements-multi-picker-fields-placement__field--alt")
    assert_selector(".f-c-file-placements-multi-picker-fields-placement__field--folio_embed_data")
  end

  def test_single_placement_attribute
    placement = create(:folio_file_placement_image_or_embed)
    view = vc_test_controller.view_context
    view.simple_form_for(placement, url: "/") do |g|
      render_inline(Folio::Console::FilePlacements::MultiPickerFields::PlacementComponent.new(
        g:,
        non_unique_file_id: false,
        placement_key: :file_placements,
        placement_attributes: %i[title],
      ))
    end

    assert_selector(".f-c-file-placements-multi-picker-fields-placement__field--title", count: 1)
    assert_no_selector(".f-c-file-placements-multi-picker-fields-placement__field--description")
    assert_no_selector(".f-c-file-placements-multi-picker-fields-placement__field--alt")
  end

  def test_rendered_multi_picker_shows_add_embed_tab_when_folio_embed_data_in_placement_attributes
    page = create(:folio_page)
    view = vc_test_controller.view_context
    vc_test_controller.stub(:url_for, "http://www.example.com/picker") do
      view.simple_form_for(page, url: "/") do |f|
        render_inline(Folio::Console::FilePlacements::MultiPickerFieldsComponent.new(
          f:,
          placement_klass: Folio::FilePlacement::ImageOrEmbed,
          placement_attributes: Folio::Console::FilePlacements::MultiPickerFieldsComponent::DEFAULT_PLACEMENT_ATTRIBUTES,
        ))
      end
    end

    assert_selector(".f-c-file-placements-multi-picker-fields__source-header .f-c-ui-tabs__nav-item", count: 2)
    assert_selector(:button, text: I18n.t("folio.console.file_placements.multi_picker_fields_component.add_embed"))
  end

  def test_rendered_multi_picker_hides_add_embed_tab_without_folio_embed_data_in_placement_attributes
    page = create(:folio_page)
    view = vc_test_controller.view_context
    vc_test_controller.stub(:url_for, "http://www.example.com/picker") do
      view.simple_form_for(page, url: "/") do |f|
        render_inline(Folio::Console::FilePlacements::MultiPickerFieldsComponent.new(
          f:,
          placement_klass: Folio::FilePlacement::ImageOrEmbed,
          placement_attributes: %i[title],
        ))
      end
    end

    assert_selector(".f-c-file-placements-multi-picker-fields__source-header .f-c-ui-tabs__nav-item", count: 1)
    assert_no_selector(:button, text: I18n.t("folio.console.file_placements.multi_picker_fields_component.add_embed"))
  end
end
