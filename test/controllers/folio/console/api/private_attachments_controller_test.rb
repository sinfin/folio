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
    attachmentable = PageWithAttachments.create!(title: "PageWithAttachments")
    account = Folio::Account.last

    sign_out account

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
    assert_equal(401, json["errors"][0]["status"])
    assert_equal(0, Folio::PrivateAttachment.count)

    sign_in account

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
    assert_equal(1, Folio::PrivateAttachment.count)
  end

  test "destroy" do
    attachmentable = PageWithAttachments.create!(title: "PageWithAttachments")
    private_attachment = Folio::PrivateAttachment.create!(
      attachmentable: attachmentable,
      file: Folio::Engine.root.join("test/fixtures/folio/test.gif")
    )
    assert_equal(1, Folio::PrivateAttachment.count)
    account = Folio::Account.last

    sign_out account

    delete url_for([:console, :api, private_attachment]), params: {
      name: "private_attachment",
      type: "Folio::PrivateAttachment",
      minimal: "1",
    }
    json = response.parsed_body
    assert_equal(401, json["errors"][0]["status"])
    assert_equal(1, Folio::PrivateAttachment.count)

    sign_in account

    delete url_for([:console, :api, private_attachment]), params: {
      name: "private_attachment",
      type: "Folio::PrivateAttachment",
      minimal: "1",
    }
    assert_response :success
    assert_equal(0, Folio::PrivateAttachment.count)
  end
end
