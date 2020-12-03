# frozen_string_literal: true

require "test_helper"

class Folio::Console::PrivateAttachments::SingleDropzoneCellTest < Folio::Console::CellTest
  class PageWithAttachments < Folio::Page
    has_one :private_attachment, class_name: "Folio::PrivateAttachment",
                                 as: :attachmentable,
                                 foreign_key: :attachmentable_id,
                                 dependent: :destroy

    accepts_nested_attributes_for :private_attachment, allow_destroy: true,
                                                       reject_if: :all_blank
  end

  test "show" do
    attachmentable = PageWithAttachments.create!(title: "PageWithAttachments")

    html = cell("folio/console/private_attachments/single_dropzone",
                attachmentable,
                name: "private_attachment",
                type: "Folio::PrivateAttachment",
                minimal: "1").(:show)
    assert html.has_css?(".f-c-private-attachments-single-dropzone--minimal")
    assert html.has_css?(".f-c-private-attachments-single-dropzone__upload-ico")

    html = cell("folio/console/private_attachments/single_dropzone",
                attachmentable,
                name: "private_attachment",
                type: "Folio::PrivateAttachment",
                minimal: false).(:show)
    assert_not html.has_css?(".f-c-private-attachments-single-dropzone--minimal")
    assert_not html.has_css?(".f-c-private-attachments-single-dropzone__upload-ico")
    assert html.has_css?(".f-c-private-attachments-single-dropzone__upload-btn")

    Folio::PrivateAttachment.create!(
      attachmentable: attachmentable,
      file: Folio::Engine.root.join("test/fixtures/folio/test.gif")
    )
    attachmentable.reload

    html = cell("folio/console/private_attachments/single_dropzone",
                attachmentable,
                name: "private_attachment",
                type: "Folio::PrivateAttachment",
                minimal: "1").(:show)
    assert_not html.has_css?(".f-c-private-attachments-single-dropzone__destroy")

    html = cell("folio/console/private_attachments/single_dropzone",
                attachmentable,
                name: "private_attachment",
                type: "Folio::PrivateAttachment",
                minimal: false).(:show)
    assert_not html.has_css?(".f-c-private-attachments-single-dropzone__upload-btn")
    assert html.has_css?(".f-c-private-attachments-single-dropzone__upload-ico")
    assert html.has_css?(".f-c-private-attachments-single-dropzone__destroy")
  end
end
