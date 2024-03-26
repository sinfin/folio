# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::PrivateAttachmentsControllerTest < Folio::Console::BaseControllerTest
  class PageWithAttachments < Folio::Page
    has_one :private_attachment, class_name: "Folio::PrivateAttachment",
                                 as: :attachmentable,
                                 foreign_key: :attachmentable_id,
                                 dependent: :destroy

    accepts_nested_attributes_for :private_attachment, allow_destroy: true,
                                                       reject_if: :all_blank
  end

  test "create" do
    attachmentable = PageWithAttachments.create!(title: "PageWithAttachments", site: Folio.main_site)
    user = Folio::User.superadmins.last

    sign_out user

    assert_difference("Folio::PrivateAttachment.count", 0) do
      post url_for([:console, :api, Folio::PrivateAttachment]), params: {
        private_attachment: {
          file: fixture_file_upload(Folio::Engine.root.join("test/fixtures/folio/test.gif")),
          attachmentable_id: attachmentable.id,
          attachmentable_type: attachmentable.class.base_class.to_s,
        },
        name: "private_attachment",
        type: "Folio::PrivateAttachment",
      }
      json = response.parsed_body
      assert_equal(401, json["errors"][0]["status"], json)
    end

    sign_in user

    assert_difference("Folio::PrivateAttachment.count", 1) do
      post url_for([:console, :api, Folio::PrivateAttachment]), params: {
        private_attachment: {
          file: fixture_file_upload(Folio::Engine.root.join("test/fixtures/folio/test.gif")),
          attachmentable_id: attachmentable.id,
          attachmentable_type: attachmentable.class.base_class.to_s,
        },
        name: "private_attachment",
        type: "Folio::PrivateAttachment",
      }
      assert_response :success
    end
  end

  test "destroy" do
    attachmentable = PageWithAttachments.create!(title: "PageWithAttachments", site: Folio.main_site)
    private_attachment = Folio::PrivateAttachment.create!(
      attachmentable:,
      file: Folio::Engine.root.join("test/fixtures/folio/test.gif")
    )
    user = Folio::User.superadmins.last

    sign_out user

    assert_difference("Folio::PrivateAttachment.count", 0) do
      delete url_for([:console, :api, private_attachment]), params: {
        name: "private_attachment",
        type: "Folio::PrivateAttachment",
        minimal: "1",
      }
      json = response.parsed_body
      assert_equal(401, json["errors"][0]["status"], json)
    end

    sign_in user

    assert_difference("Folio::PrivateAttachment.count", -1) do
      delete url_for([:console, :api, private_attachment]), params: {
        name: "private_attachment",
        type: "Folio::PrivateAttachment",
        minimal: "1",
      }
      assert_response :success
    end
  end
end
