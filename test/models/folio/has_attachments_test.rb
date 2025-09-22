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
    document = create(:folio_file_document)

    my_page = MyPage.create!(title: "MyPage",
                             site: get_any_site,
                             my_file_placement_attributes: { file: document })

    assert_equal(1, MyFilePlacement.count)
    assert_equal(document, my_page.my_file)
  end

  test "folio_attachments_first_image_as_cover" do
    class FirstAsCover < Folio::Page
      folio_attachments_first_image_as_cover
    end

    page = FirstAsCover.create!(title: "FirstAsCover", site: get_any_site)

    one = create(:folio_file_image)
    two = create(:folio_file_image)
    three = create(:folio_file_image)

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

  test "file placement counter implementation" do
    class CounterTestPage < Folio::Page
      attr_accessor :image_placements_count

      attr_writer :image_placements_count

      attr_reader :image_placements_count
    end

    image1 = create(:folio_file_image)
    image2 = create(:folio_file_image)
    image3 = create(:folio_file_image)

    page = CounterTestPage.create!(title: "Counter Test Page", site: get_any_site)

    page.update!(image_placements_attributes: [
      { file_id: image1.id, position: 1 },
      { file_id: image2.id, position: 2 }
    ])

    assert_equal 2, page.image_placements_count, "Counter should be set to 2 after nested attributes update"
    assert_equal 2, page.image_placements.count, "Should have 2 image placements"

    placement_ids = page.image_placements.map(&:id)
    page.update!(image_placements_attributes: [
      { id: placement_ids[0], _destroy: true },
      { id: placement_ids[1], position: 1 },
      { file_id: image3.id, position: 2 }
    ])

    assert_equal 2, page.image_placements_count, "Counter should remain 2 after replacing one placement"
    assert_equal 2, page.image_placements.count, "Should still have 2 image placements"

    page.image_placements_count = 2
    new_placement = page.image_placements.create!(file: image1, position: 3)

    assert_equal 3, page.reload.image_placements_count, "Counter should be updated after direct placement creation"

    new_placement.destroy!

    assert_equal 2, page.reload.image_placements_count, "Counter should be updated after direct placement deletion"

    # Test destroying an existing placement via nested attributes
    existing_placements = page.image_placements.to_a
    page.update!(image_placements_attributes: [
      { id: existing_placements[0].id, _destroy: true },
      { id: existing_placements[1].id, position: 1 }
    ])

    assert_equal 1, page.image_placements_count, "Counter should reflect destroyed placement"

    remaining_placement = page.image_placements.first
    page.update!(image_placements_attributes: [
      { id: remaining_placement.id, position: 1 },
      { file_id: image1.id, position: 2, _destroy: false },
      { file_id: image2.id, position: 3, _destroy: true }
    ])

    assert_equal 2, page.image_placements_count, "Counter should not include placements marked for destruction"

    page.image_placements_count = nil
    page.images = [image1, image2, image3]
    page.save!

    assert_equal 3, page.image_placements_count, "Counter should be updated when setting images directly"
  end
end
