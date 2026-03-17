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
end
