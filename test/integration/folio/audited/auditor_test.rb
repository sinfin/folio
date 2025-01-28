# frozen_string_literal: true

require "test_helper"

class Folio::Audited::AuditorTest < ActionDispatch::IntegrationTest
  test "get_folio_audited_data_file_placements" do
    page = create(:folio_page)
    image = create(:folio_file_image)

    auditor = Folio::Audited::Auditor.new(record: page)

    assert_equal({}, auditor.send(:get_folio_audited_data_file_placements))

    page.update!(cover_placement_attributes: { file_id: image.id })
    page.reload
    auditor = Folio::Audited::Auditor.new(record: page)

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
    auditor = Folio::Audited::Auditor.new(record: page)

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
    auditor = Folio::Audited::Auditor.new(record: page)

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

  test "get_folio_audited_changed_relations" do
    page = create(:folio_page)
    image = create(:folio_file_image)

    assert_equal [],
                 Folio::Audited::Auditor.new(record: page).get_folio_audited_changed_relations

    page.assign_attributes(cover_placement_attributes: { file_id: image.id })
    assert_equal ["file_placements"],
                 Folio::Audited::Auditor.new(record: page).get_folio_audited_changed_relations

    page.save!
    assert_equal [],
                 Folio::Audited::Auditor.new(record: page).get_folio_audited_changed_relations

    page.assign_attributes(atoms_attributes: { 0 => { type: "Dummy::Atom::Contents::Text", position: 1, content: "atom 1" } })
    assert_equal ["atoms"],
                 Folio::Audited::Auditor.new(record: page).get_folio_audited_changed_relations

    page.save!
    assert_equal [],
                 Folio::Audited::Auditor.new(record: page).get_folio_audited_changed_relations

    page.assign_attributes(atoms_attributes: { 0 => { id: page.atoms.first.id, _destroy: "1" } },
                           cover_placement_attributes: { id: page.cover_placement.id, _destroy: "1" })
    assert_equal ["atoms", "file_placements"],
                 Folio::Audited::Auditor.new(record: page).get_folio_audited_changed_relations

    page.save!
    assert_equal [],
                 Folio::Audited::Auditor.new(record: page.reload).get_folio_audited_changed_relations
  end
end
