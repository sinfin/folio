# frozen_string_literal: true

require "test_helper"

class Folio::Console::PrivateAttachmentsFieldsComponentTest < Folio::Console::ComponentTest
  test "renders uppy with the add button as custom trigger" do
    render_component

    assert_selector(".f-c-private-attachments-fields")
    assert_selector('.f-c-private-attachments-fields[data-action*="f-uppy:upload-start->f-c-private-attachments-fields#onUppyUploadStart"]')
    assert_selector('.f-c-private-attachments-fields[data-action*="f-uppy:upload-success->f-c-private-attachments-fields#onUppyUploadSuccess"]')
    assert_selector('.f-uppy.f-uppy--custom-trigger[data-f-uppy-file-type-value="Folio::PrivateAttachment"]')
    assert_selector(".f-uppy__trigger .f-c-ui-button", text: I18n.t("folio.console.actions.add"))
    assert_no_selector(".f-c-private-attachments-fields__attachment-progress", visible: :all)
    assert_selector(".f-c-private-attachments-fields__action--move-up", visible: :all)
    assert_selector(".f-c-private-attachments-fields__action--move-down", visible: :all)
  end

  test "limits uppy to one file and hides move buttons in single mode" do
    render_component(single: true)

    assert_selector('.f-uppy[data-f-uppy-max-number-of-files-value="1"]')
    assert_no_selector(".f-c-private-attachments-fields__action--move-up", visible: :all)
    assert_no_selector(".f-c-private-attachments-fields__action--move-down", visible: :all)
  end

  private
    def render_component(single: false)
      page = Dummy::Page::WithPrivateAttachments.new(site: get_any_site,
                                                     title: "Page with private attachments")
      view = vc_test_controller.view_context

      view.simple_form_for(page, url: "/") do |f|
        render_inline(Folio::Console::PrivateAttachmentsFieldsComponent.new(f:, single:))
      end
    end
end
