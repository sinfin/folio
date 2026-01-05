# frozen_string_literal: true

require "test_helper"

class Folio::HasAttachmentsTest < ActiveSupport::TestCase
  class CounterTestPage < Folio::Page
    attr_accessor :image_placements_count

    def update_column(name, value)
      if name.to_sym == :image_placements_count
        self.image_placements_count = value
      else
        super
      end
    end
  end

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

  test "file placement counter implementation via direct destruction of placement" do
    page = CounterTestPage.create!(title: "Counter Test Page", site: get_any_site)

    page.update!(image_placements_attributes: [
      { file_id: create(:folio_file_image).id },
    ])

    assert_equal 1, page.image_placements_count

    page.image_placements.reload.last.destroy!
    assert_equal 0, page.reload.image_placements_count
  end

  test "validate_files_usage_limits_if_publishing - allows publishing with only author" do
    file = create(:folio_file_image,
                  author: "Test Author",
                  attribution_source: nil,
                  attribution_source_url: nil)

    page = create(:folio_page, :unpublished, site: get_any_site)
    page.cover_placement = create(:folio_file_placement_cover,
                                  file: file,
                                  placement: page)

    page.published = true
    assert page.valid?
    assert_empty page.errors[:base]
  end

  test "validate_files_usage_limits_if_publishing - allows publishing with only attribution_source" do
    file = create(:folio_file_image,
                  author: nil,
                  attribution_source: "Test Source",
                  attribution_source_url: nil)

    page = create(:folio_page, :unpublished, site: get_any_site)
    page.cover_placement = create(:folio_file_placement_cover,
                                  file: file,
                                  placement: page)

    page.published = true
    assert page.valid?
    assert_empty page.errors[:base]
  end

  test "validate_files_usage_limits_if_publishing - allows publishing with only attribution_source_url" do
    file = create(:folio_file_image,
                  author: nil,
                  attribution_source: nil,
                  attribution_source_url: "http://example.com")

    page = create(:folio_page, :unpublished, site: get_any_site)
    page.cover_placement = create(:folio_file_placement_cover,
                                  file: file,
                                  placement: page)

    page.published = true
    assert page.valid?
    assert_empty page.errors[:base]
  end

  test "validate_files_usage_limits_if_publishing - allows publishing with author and attribution_source" do
    file = create(:folio_file_image,
                  author: "Test Author",
                  attribution_source: "Test Source",
                  attribution_source_url: nil)

    page = create(:folio_page, :unpublished, site: get_any_site)
    page.cover_placement = create(:folio_file_placement_cover,
                                  file: file,
                                  placement: page)

    page.published = true
    assert page.valid?
    assert_empty page.errors[:base]
  end

  test "validate_files_usage_limits_if_publishing - allows publishing with all attribution fields present" do
    file = create(:folio_file_image,
                  author: "Test Author",
                  attribution_source: "Test Source",
                  attribution_source_url: "http://example.com")

    page = create(:folio_page, :unpublished, site: get_any_site)
    page.cover_placement = create(:folio_file_placement_cover,
                                  file: file,
                                  placement: page)

    page.published = true
    assert page.valid?
    assert_empty page.errors[:base]
  end

  test "validate_files_usage_limits_if_publishing - only validates usage limits when publishing" do
    file = create(:folio_file_image,
                  author: nil,
                  attribution_source: nil,
                  attribution_source_url: nil)

    page = create(:folio_page, :unpublished, site: get_any_site)
    page.cover_placement = create(:folio_file_placement_cover,
                                  file: file,
                                  placement: page)

    assert page.valid?
    assert_empty page.errors[:base]
  end

  test "does not validate placements marked for destruction" do
    # Ensure config is false initially so test works regardless of global config
    page = nil
    placement_id = nil

    Rails.application.config.stub(:folio_files_require_attribution, false) do
      page = create(:folio_page, published: true)
      invalid_image = create(:folio_file_image,
                             author: nil,
                             attribution_source: nil,
                             attribution_source_url: nil)

      # Create an invalid placement (with config false, this will succeed)
      page.update!(image_placements_attributes: [
        { file_id: invalid_image.id, position: 1 }
      ])
      placement_id = page.image_placements.first.id
    end

    # With attribution required and page published, this should fail validation
    Rails.application.config.stub(:folio_files_require_attribution, true) do
      page.reload
      assert_not page.valid?
      assert page.errors[:image_placements].present?

      # Now mark the invalid placement for destruction
      page.update(image_placements_attributes: [
        { id: placement_id, _destroy: true }
      ])

      # Page should be valid now since the invalid placement is being removed
      assert page.valid?, "Page should be valid when invalid placement is marked for destruction"
      assert page.errors[:image_placements].blank?, "Should not have validation errors for marked_for_destruction placements"
    end
  end

  test "get_files_with_usage_constraints uses in-memory placements when replacing cover" do
    # Create page with invalid cover (missing attribution_source) - but don't publish yet
    page = create(:folio_page, published: false)
    invalid_image = create(:folio_file_image,
                           attribution_source: nil,
                           attribution_max_usage_count: 10,
                           published_usage_count: 5)
    valid_image = create(:folio_file_image,
                         attribution_source: "Valid Source",
                         attribution_max_usage_count: 10,
                         published_usage_count: 5)

    # Set invalid cover and save to database
    page.update!(cover_placement_attributes: { file_id: invalid_image.id })
    cover_placement_id = page.cover_placement.id

    # Verify invalid image is set in database
    assert_equal invalid_image.id, page.reload.cover.id

    # Replace cover with valid image via nested attributes WITHOUT saving (using assign_attributes)
    # This updates the in-memory association but database still has old file_id
    page.assign_attributes(cover_placement_attributes: { id: cover_placement_id, file_id: valid_image.id })

    # Verify the placement's file_id was updated in memory
    assert_equal valid_image.id, page.cover_placement.file_id, "Cover placement file_id should be updated to valid image in memory"

    # Verify database still has old file_id (this is the key - DB hasn't been updated yet)
    db_file_id = Folio::FilePlacement::Cover.find_by(id: cover_placement_id)&.file_id
    assert_equal invalid_image.id, db_file_id, "Database should still have old invalid image"

    # Now try to publish - get_files_with_usage_constraints should use the new valid image from memory, not query old from DB
    page.published = true

    # The bug: get_files_with_usage_constraints queries DB and gets old file_id, causing validation error
    # Verify that get_files_with_usage_constraints returns the new file from memory, not the old one from DB
    files_with_constraints = page.send(:get_files_with_usage_constraints)
    assert_includes files_with_constraints, valid_image, "get_files_with_usage_constraints should return the new valid image from memory"
    assert_not_includes files_with_constraints, invalid_image, "get_files_with_usage_constraints should not return the old invalid image from DB"

    # Page should be valid now with the new valid image (not validating the old invalid one from DB)
    assert page.valid?, "Page should be valid when invalid cover is replaced with valid cover - should validate new file from memory, not old one from DB"
    assert page.errors[:cover_placement].blank?, "Should not have validation errors for valid cover image"

    assert page.save, "Page should save successfully with valid cover image"

    # After reload, the new valid image should be there
    page.reload
    assert_equal valid_image.id, page.cover.id, "Cover should be updated to the new valid image"
  end
end
