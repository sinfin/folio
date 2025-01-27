# frozen_string_literal: true

require "test_helper"

class Folio::Audited::AuditorTest < ActionDispatch::IntegrationTest
  test "get_folio_audited_data_file_placements" do
    page = create(:folio_page)
    image = create(:folio_file_image)

    auditor = Folio::Audited::Auditor.new(page)

    assert_equal({}, auditor.send(:get_folio_audited_data_file_placements))

    page.update!(cover_placement_attributes: { file_id: image.id })
    page.reload
    auditor = Folio::Audited::Auditor.new(page)

    assert_equal({
      "cover_placement" => {
        "id" => page.cover_placement.id,
        "file_id" => image.id,
        "position" => 1,
        "type" => "Folio::FilePlacement::Cover",
      }
    }, auditor.send(:get_folio_audited_data_file_placements))

    page.images << image
    page.reload
    auditor = Folio::Audited::Auditor.new(page)

    assert_equal({
      "cover_placement" => {
        "id" => page.cover_placement.id,
        "file_id" => image.id,
        "position" => 1,
        "type" => "Folio::FilePlacement::Cover",
      },
      "image_placements" => [{
        "id" => page.image_placements.last.id,
        "file_id" => image.id,
        "position" => 1,
        "type" => "Folio::FilePlacement::Image",
      }]
    }, auditor.send(:get_folio_audited_data_file_placements))

    page.update!(cover_placement_attributes: { id: page.cover_placement.id, _destroy: "1" })

    page.reload
    auditor = Folio::Audited::Auditor.new(page)

    assert_equal({
      "image_placements" => [{
        "id" => page.image_placements.last.id,
        "file_id" => image.id,
        "position" => 1,
        "type" => "Folio::FilePlacement::Image",
      }]
    }, auditor.send(:get_folio_audited_data_file_placements))

    page.update!(image_placements_attributes: {
      page.image_placements.last.id => { id: page.image_placements.last.id, _destroy: "1" }
    })

    assert_equal({}, auditor.send(:get_folio_audited_data_file_placements))
  end
end
