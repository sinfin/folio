# frozen_string_literal: true

require "test_helper"

class Folio::Audited::AuditorTest < ActionDispatch::IntegrationTest
  class AuditedPage < Folio::Page
    include Folio::Audited::Model
    audited
  end

  test "get_folio_audited_data_file_placements" do
    Audited.stub(:auditing_enabled, true) do
      site = get_any_site
      page = AuditedPage.create!(title: "v1", site:)

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
  end

  test "get_folio_audited_changed_relations" do
    Audited.stub(:auditing_enabled, true) do
      site = get_any_site

      page = AuditedPage.create!(title: "v1", site:)
      image = create(:folio_file_image, site:)

      assert_equal [],
                   Folio::Audited::Auditor.new(record: page).get_folio_audited_changed_relations

      page.reload.assign_attributes(cover_placement_attributes: { file_id: image.id })
      assert_equal ["cover_placement"],
                   Folio::Audited::Auditor.new(record: page).get_folio_audited_changed_relations

      page.save!
      assert_equal [],
                   Folio::Audited::Auditor.new(record: page).get_folio_audited_changed_relations

      assert page.audits.last.folio_data["file_placements"]["cover_placement"]["id"]

      page.reload.assign_attributes(atoms_attributes: { 0 => { type: "Dummy::Atom::Contents::Text", position: 1, content: "atom 1" } })
      assert_equal ["atoms"],
                   Folio::Audited::Auditor.new(record: page).get_folio_audited_changed_relations

      page.save!
      assert_equal [],
                   Folio::Audited::Auditor.new(record: page).get_folio_audited_changed_relations
      assert page.audits.last.folio_data["atoms"]["atoms"][0]["id"]

      page.reload.assign_attributes(atoms_attributes: { 0 => { id: page.atoms.first.id, _destroy: "1" } },
                                    cover_placement_attributes: { id: page.cover_placement.id, _destroy: "1" })
      assert_equal ["atoms", "cover_placement"],
                   Folio::Audited::Auditor.new(record: page).get_folio_audited_changed_relations

      page.save!
      assert_equal [],
                   Folio::Audited::Auditor.new(record: page.reload).get_folio_audited_changed_relations
      assert_equal [], page.audits.last.folio_data["atoms"]["atoms"]
      assert_equal({}, page.audits.last.folio_data["file_placements"])
    end
  end
end
