# frozen_string_literal: true

require "test_helper"

class Folio::AuditedTest < ActiveSupport::TestCase
  class AuditedPage < Folio::Page
    include Folio::Audited
    audited
  end

  test "audited model & atoms" do
    Audited.stub(:auditing_enabled, true) do
      site = get_any_site
      # version 1
      @page = AuditedPage.create(title: "v1",
                                 site:,
                                 atoms_attributes: { 0 => { type: "Dummy::Atom::Contents::Text", position: 1, content: "atom 1 v1" } })

      assert_equal 1, @page.atoms.count
      assert_equal 1, @page.revisions.size

      # version 2
      @page.update!(title: "v2",
                    atoms_attributes: {
                      1 => { type: "Dummy::Atom::Contents::Text", position: 2, content: "atom 2 v2" }
                    })

      assert_equal 2, @page.atoms.count
      assert_equal 2, @page.revisions.size

      # version 3
      @page.update!(title: "v3",
                    atoms_attributes: {
                      @page.atoms.first.id => { id: @page.atoms.first.id, content: "atom 1 v3" },
                      @page.atoms.second.id => { id: @page.atoms.second.id, content: "atom 2 v3" },
                    })

      assert_equal 2, @page.atoms.count
      assert_equal 3, @page.revisions.size

      # version 4
      @page.update!(title: "v4",
                    atoms_attributes: {
                      @page.atoms.second.id => { id: @page.atoms.second.id, _destroy: "1" },
                    })

      assert_equal 1, @page.atoms.count
      assert_equal 4, @page.revisions.size

      # version 5
      @page.update!(title: "v5",
                    atoms_attributes: { 0 => { type: "Dummy::Atom::Contents::Text", content: "atom 3 v5" } })

      assert_equal 2, @page.atoms.count
      assert_equal 5, @page.revisions.size

      current_page_atom_1 = @page.atoms.first
      current_page_atom_2 = @page.atoms.second

      # revision version 1
      revision = @page.revisions.first
      atoms_hash = revision.get_atoms_attributes_for_reconstruction["atoms_attributes"]

      assert_equal "v1", revision.title

      assert_equal current_page_atom_1.id, atoms_hash.first["id"]
      assert_equal "1", atoms_hash.first["_destroy"]

      assert_equal current_page_atom_2.id, atoms_hash.second["id"]
      assert_equal "1", atoms_hash.second["_destroy"]

      assert_nil atoms_hash.third["id"]
      assert_nil atoms_hash.third["_destroy"]
      assert_equal "atom 1 v1", atoms_hash.third["data"]["content"]

      puts "ayooo"

      # revision version 2
      revision = @page.revisions.second
      atoms_hash = revision.get_atoms_attributes_for_reconstruction["atoms_attributes"]

      assert_equal "v2", revision.title

      assert_equal current_page_atom_1.id, atoms_hash.first["id"]
      assert_nil atoms_hash.first["_destroy"]
      assert_equal "atom 1 v1", atoms_hash.first["data"]["content"]

      assert_equal current_page_atom_2.id, atoms_hash.second["id"]
      assert_equal "1", atoms_hash.second["_destroy"]

      # revision version 4
      revision = @page.revisions.fourth
      atoms_hash = revision.get_atoms_attributes_for_reconstruction["atoms_attributes"]

      assert_equal "v4", revision.title
      assert_equal 1, atoms_hash.size
      assert_equal 2, @page.atoms_hash.count

      revision = @page.audits.third.revision
      revision.reconstruct_atoms
      revision.save!

      @page.reload

      assert_equal "v3", @page.title
      assert_equal "atom 1 v3", @page.atoms.first.content
      assert_equal "atom 2 v3", @page.atoms.second.content
    end
  end

  test "audited model & file placements" do
    Audited.stub(:auditing_enabled, true) do
      site = get_any_site

      image_1 = create(:folio_file_image)
      image_2 = create(:folio_file_image)

      @page = AuditedPage.create(title: "v1",
                                 site:,
                                 cover_placement_attributes: { file_id: image_1.id })

      assert_equal 1, @page.revisions.size

      @page.update!(title: "v2",
                    cover_placement_attributes: { id: @page.cover_placement.id, file_id: image_2.id },
                    image_placements_attributes: { 0 => { file_id: image_1.id, position: 1 } })

      assert_equal 2, @page.revisions.size

      @page.reload

      @page.update!(title: "v3",
                    cover_placement_attributes: { id: @page.cover_placement.id, _destroy: "1" },
                    image_placements_attributes: { 0 => { id: @page.image_placements.first.id, _destroy: "1" } })

      assert_equal 3, @page.revisions.size

      # revision version 1
      revision = @page.revisions.first
      file_placements_hash = revision.get_file_placements_attributes_for_reconstruction(record: revision)

      assert_equal "v1", revision.title
      assert_equal image_1.id, file_placements_hash["cover_placement_attributes"]["file_id"]
      assert_nil file_placements_hash["image_placements_attributes"]

      # revision version 2
      revision = @page.revisions.second
      file_placements_hash = revision.get_file_placements_attributes_for_reconstruction(record: revision)

      assert_equal "v2", revision.title
      assert_equal image_2.id, file_placements_hash["cover_placement_attributes"]["file_id"]
      assert_equal 1, file_placements_hash["image_placements_attributes"].size
      assert_equal image_1.id, file_placements_hash["image_placements_attributes"].first["file_id"]

      # revision version 3
      revision = @page.revisions.third
      file_placements_hash = revision.get_file_placements_attributes_for_reconstruction(record: revision)

      assert_equal "v3", revision.title
      assert_nil file_placements_hash["cover_placement_attributes"]
      assert_nil file_placements_hash["image_placements_attributes"]

      revision = @page.audits.second.revision
      revision.reconstruct_file_placements
      revision.save!

      @page.reload

      assert_equal "v2", @page.title

      assert_equal image_2.id, @page.cover_placement.file_id
      assert_equal 1, @page.image_placements.size
      assert_equal image_1.id, @page.image_placements.first.file_id
    end
  end
end
