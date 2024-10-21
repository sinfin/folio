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

  test "folio_attachments_to_audited_hash" do
    page = create(:folio_page)
    image = create(:folio_file_image)

    assert_equal({}, page.folio_attachments_to_audited_hash)

    page.update!(cover: image)
    page.reload

    assert_equal({
      "cover_placement" => {
        "id" => page.cover_placement.id,
        "file_id" => image.id,
        "position" => 1,
        "type" => "Folio::FilePlacement::Cover",
        "key" => "cover_placement",
      }
    }, page.folio_attachments_to_audited_hash)

    page.images << image
    page.reload

    assert_equal({
      "cover_placement" => {
        "id" => page.cover_placement.id,
        "file_id" => image.id,
        "position" => 1,
        "type" => "Folio::FilePlacement::Cover",
        "key" => "cover_placement",
      },
      "image_placements" => [{
        "id" => page.image_placements.last.id,
        "file_id" => image.id,
        "position" => 1,
        "type" => "Folio::FilePlacement::Image",
        "key" => "image_placements",
      }]
    }, page.folio_attachments_to_audited_hash)

    page.update!(cover_placement_attributes: { id: page.cover_placement.id, _destroy: "1" })

    page.reload

    assert_equal({
      "image_placements" => [{
        "id" => page.image_placements.last.id,
        "file_id" => image.id,
        "position" => 1,
        "type" => "Folio::FilePlacement::Image",
        "key" => "image_placements",
      }]
    }, page.folio_attachments_to_audited_hash)

    page.update!(image_placements_attributes: {
      page.image_placements.last.id => { id: page.image_placements.last.id, _destroy: "1" }
    })

    assert_equal({}, page.folio_attachments_to_audited_hash)
  end
end
