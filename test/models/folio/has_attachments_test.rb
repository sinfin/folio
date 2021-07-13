# frozen_string_literal: true

require "test_helper"

class Folio::HasAttachmentsTest < ActiveSupport::TestCase
  test "has_one_document_placement" do
    class MyFilePlacement < Folio::FilePlacement::Base
      folio_document_placement :my_file_placement
    end

    class MyPage < Folio::Page
      has_one_placement :my_file,
                        placement: "Folio::HasAttachmentsTest::MyFilePlacement"
    end

    assert_equal(0, MyFilePlacement.count)
    document = create(:folio_document)

    my_page = MyPage.create!(title: "MyPage",
                             my_file_placement_attributes: { file: document })

    assert_equal(1, MyFilePlacement.count)
    assert_equal(document, my_page.my_file)
  end

  test "folio_attachments_first_image_as_cover" do
    class FirstAsCover < Folio::Page
      folio_attachments_first_image_as_cover
    end

    page = FirstAsCover.create!(title: "FirstAsCover")

    one = create(:folio_image)
    two = create(:folio_image)
    three = create(:folio_image)

    page.update!(image_placements_attributes: [{ file_id: one.id, position: 1 }])
    assert page.reload.cover
    assert_equal one.id, page.cover.id

    page.update!(image_placements_attributes: [{ file_id: two.id, position: 2 }, { file_id: three.id, position: 3 }])

    assert page.reload.cover
    assert_equal one.id, page.cover.id

    original_placements = page.image_placements.to_a

    assert_equal original_placements[0].file_id, page.cover.id

    page.update!(image_placements_attributes: [
      { id: original_placements[0].id, position: 2 },
      { id: original_placements[1].id, position: 1 },
      { id: original_placements[2].id, position: 3 },
    ])

    assert page.reload.cover
    assert_equal [
      original_placements[1].id,
      original_placements[0].id,
      original_placements[2].id,
    ], page.image_placements.map(&:id)

    assert_equal original_placements[1].file_id, page.cover.id
  end
end
