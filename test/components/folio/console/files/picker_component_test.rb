# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::PickerComponentTest < Folio::Console::ComponentTest
  test "renders placement validation error" do
    page = build(:folio_page)
    page.errors.add(:cover_placement, :blank)

    view = vc_test_controller.view_context
    view.simple_form_for(page, url: "/") do |f|
      render_inline(Folio::Console::Files::PickerComponent.new(
        f:,
        placement_key: :cover_placement,
        file_klass: Folio::File::Image,
      ))
    end

    assert_selector(".f-c-files-picker.f-c-files-picker--invalid .invalid-feedback",
                    text: page.errors.full_messages_for(:cover_placement).first)
  end

  test "does not render placement validation error without errors" do
    page = build(:folio_page)

    view = vc_test_controller.view_context
    view.simple_form_for(page, url: "/") do |f|
      render_inline(Folio::Console::Files::PickerComponent.new(
        f:,
        placement_key: :cover_placement,
        file_klass: Folio::File::Image,
      ))
    end

    assert_no_selector(".f-c-files-picker .invalid-feedback")
  end
end
