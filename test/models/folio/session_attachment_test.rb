# frozen_string_literal: true

require "test_helper"

class Folio::SessionAttachmentTest < ActiveSupport::TestCase
  test "type" do
    id = "123"
    image = Folio::Engine.root.join("test/fixtures/folio/test.gif")

    assert_not Folio::SessionAttachment::Base.new(web_session_id: id,
                                                  file: image).valid?
    assert_not Folio::SessionAttachment::Document.new(web_session_id: id,
                                                      file: image).valid?
    assert_not Folio::SessionAttachment::Image.new(web_session_id: id,
                                                   file: image).valid?

    assert Dummy::SessionAttachment::Document.new(web_session_id: id,
                                                  file: image).valid?
    assert Dummy::SessionAttachment::Image.new(web_session_id: id,
                                               file: image).valid?
  end

  test "image format validation" do
    id = "123"
    image = Folio::Engine.root.join("test/fixtures/folio/test.gif")
    doc = Folio::Engine.root.join("test/fixtures/folio/empty.pdf")

    assert Dummy::SessionAttachment::Image.new(web_session_id: id,
                                               file: image).valid?

    assert_not Dummy::SessionAttachment::Image.new(web_session_id: id,
                                                   file: doc).valid?
  end

  test "clear_unpaired!" do
    id = "123"
    image = Folio::Engine.root.join("test/fixtures/folio/test.gif")
    sa = Dummy::SessionAttachment::Image.create!(file: image,
                                                 web_session_id: id)
    assert_equal(1, Folio::SessionAttachment::Base.count)

    assert_difference("Folio::SessionAttachment::Base.count", 0) do
      Folio::SessionAttachment::Base.clear_unpaired!
    end

    assert_difference("Folio::SessionAttachment::Base.count", -1) do
      sa.update_column(:created_at, 3.days.ago)
      Folio::SessionAttachment::Base.clear_unpaired!
    end
  end
end
