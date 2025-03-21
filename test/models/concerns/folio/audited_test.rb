# frozen_string_literal: true

require "test_helper"

class Folio::AuditedTest < ActiveSupport::TestCase
  class AuditedPage < Folio::Page
    include Folio::Audited::Model
    audited

    validates :cover_placement,
              presence: true,
              if: :should_validate_cover_placement_in_test

    attr_accessor :should_validate_cover_placement_in_test
  end

  class AuditedPageTwo < Folio::Page
    include Folio::Audited::Model

    audited

    def should_audit_changes?
      title != "no audit"
    end
  end

  class PageReferenceAtom < Folio::Atom::Base
    STRUCTURE = {
      content: :string,
    }

    ASSOCIATIONS = {
      page: %i[Folio::Page]
    }

    validates :page, :content,
              presence: true
  end

  test "audited model and atoms" do
    site = get_any_site
    page_one = create(:folio_page, site:)
    page_two = create(:folio_page, site:)

    Audited.stub(:auditing_enabled, true) do
      # version 1
      @page = AuditedPage.create(title: "v1",
                                 site:,
                                 atoms_attributes: { 0 => { type: "Folio::AuditedTest::PageReferenceAtom", position: 1, content: "atom 1 v1", page: page_one } })

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
                      @page.atoms.first.id => { id: @page.atoms.first.id, content: "atom 1 v3", page: page_two },
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
      audit = @page.audits.first
      revision = audit.revision
      auditor = Folio::Audited::Auditor.new(record: revision)
      atoms_hash = auditor.send(:get_atoms_attributes_for_reconstruction, record: revision, audit:)["atoms_attributes"]

      assert_equal current_page_atom_1.id, atoms_hash.first["id"]
      assert_equal "atom 1 v1", atoms_hash.first["data"]["content"]
      assert_equal page_one.id, atoms_hash.first["associations"]["page"]["id"]
      assert_nil atoms_hash.first["_destroy"]

      assert_equal current_page_atom_2.id, atoms_hash.second["id"]
      assert_equal "1", atoms_hash.second["_destroy"]

      # revision version 2
      audit = @page.audits.second
      revision = audit.revision
      auditor = Folio::Audited::Auditor.new(record: revision)
      atoms_hash = auditor.send(:get_atoms_attributes_for_reconstruction, record: revision, audit:)["atoms_attributes"]

      assert_equal "v2", revision.title

      assert_equal current_page_atom_1.id, atoms_hash.first["id"]
      assert_nil atoms_hash.first["_destroy"]
      assert_equal "atom 1 v1", atoms_hash.first["data"]["content"]

      assert_equal current_page_atom_2.id, atoms_hash.second["id"]
      assert_equal "1", atoms_hash.second["_destroy"]

      # revision version 4
      audit = @page.audits.fourth
      revision = audit.revision
      auditor = Folio::Audited::Auditor.new(record: revision)
      atoms_hash = auditor.send(:get_atoms_attributes_for_reconstruction, record: revision, audit:)["atoms_attributes"]

      assert_equal "v4", revision.title
      assert_equal 2, atoms_hash.size
      assert_nil(atoms_hash.find { |a| a["data"]["content"] == "atom 1 v3" }["_destroy"])
      assert_equal("1", atoms_hash.find { |a| a["data"]["content"] == "atom 3 v5" }["_destroy"])

      audit = @page.audits.third
      revision = audit.revision
      revision.reconstruct_folio_audited_data(audit:)
      revision.save!

      @page.reload

      assert_equal "v3", @page.title
      assert_equal "atom 1 v3", @page.atoms.first.content
      assert_equal "atom 2 v3", @page.atoms.second.content
    end
  end

  test "audited model and file placements" do
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
      audit = @page.audits.first
      revision = audit.revision
      auditor = Folio::Audited::Auditor.new(record: revision, audit:)
      file_placements_hash = auditor.send(:get_file_placements_attributes_for_reconstruction,
                                          record: revision,
                                          data: audit.folio_data && audit.folio_data["file_placements"])

      assert_equal "v1", revision.title
      assert_equal image_1.id, file_placements_hash["cover_placement_attributes"]["file_id"]
      assert_nil file_placements_hash["image_placements_attributes"]

      # revision version 2
      audit = @page.audits.second
      revision = audit.revision
      auditor = Folio::Audited::Auditor.new(record: revision, audit:)
      file_placements_hash = auditor.send(:get_file_placements_attributes_for_reconstruction,
                                          record: revision,
                                          data: audit.folio_data && audit.folio_data["file_placements"])

      assert_equal "v2", revision.title
      assert_equal image_2.id, file_placements_hash["cover_placement_attributes"]["file_id"]
      assert_equal 1, file_placements_hash["image_placements_attributes"].size
      assert_equal image_1.id, file_placements_hash["image_placements_attributes"].first["file_id"]

      # revision version 3
      audit = @page.audits.third
      revision = audit.revision
      auditor = Folio::Audited::Auditor.new(record: revision, audit:)
      file_placements_hash = auditor.send(:get_file_placements_attributes_for_reconstruction,
                                          record: revision,
                                          data: audit.folio_data && audit.folio_data["file_placements"])

      assert_equal "v3", revision.title
      assert_nil file_placements_hash["cover_placement_attributes"]
      assert_nil file_placements_hash["image_placements_attributes"]

      audit = @page.audits.second
      revision = audit.revision
      revision.reconstruct_folio_audited_data(audit:)
      revision.save!

      @page.reload

      assert_equal "v2", @page.title

      assert_equal image_2.id, @page.cover_placement.file_id
      assert_equal 1, @page.image_placements.size
      assert_equal image_1.id, @page.image_placements.first.file_id
    end
  end

  test "missing atom association record" do
    Audited.stub(:auditing_enabled, true) do
      site = get_any_site

      page_one = create(:folio_page, site:, title: "page one")
      page_two = create(:folio_page, site:, title: "page two")

      @page = AuditedPage.create(title: "v1",
                                 site:,
                                 atoms_attributes: { 0 => {
                                   type: "Folio::AuditedTest::PageReferenceAtom",
                                   position: 1,
                                   content: "atom 1 v1",
                                   page: page_one
                                 } })

      assert_equal 1, @page.atoms.count
      assert_equal 1, @page.revisions.size
      assert_equal page_one.id, @page.atoms.first.page.id

      @page.update!(title: "v2",
                    atoms_attributes: { 0 => {
                      id: @page.atoms.first.id,
                      content: "atom 1 v2",
                      page: page_two
                    } })

      assert_equal 1, @page.atoms.count
      assert_equal 2, @page.revisions.size
      assert_equal page_two.id, @page.atoms.first.page.id

      page_one.destroy!

      audit = @page.audits.first
      revision = audit.revision
      revision.reconstruct_folio_audited_data(audit:)
      revision.save!

      @page.reload

      assert_equal "v1", @page.title
      assert_equal 1, @page.atoms.count
      assert_equal "Folio::Atom::Audited::Invalid", @page.atoms.first.type
    end
  end

  test "missing attachment record" do
    Audited.stub(:auditing_enabled, true) do
      site = get_any_site

      image_1 = create(:folio_file_image)
      image_2 = create(:folio_file_image)

      @page = AuditedPage.new(title: "v1",
                              site:,
                              should_validate_cover_placement_in_test: true)

      assert_not @page.valid?

      @page.update!(cover_placement_attributes: { file_id: image_1.id },
                    atoms_attributes: {
                      1 => { type: "Dummy::Atom::Images::SingleImage", position: 1, cover_placement_attributes: { file_id: image_1.id } }
                    })

      assert_equal image_1.id, @page.cover.id
      assert_equal image_1.id, @page.atoms.first.cover.id

      @page.update!(title: "v2",
                    cover_placement_attributes: { id: @page.cover_placement.id, file_id: image_2.id },
                    atoms_attributes: { 1 => { id: @page.atoms.first.id, _destroy: true } })

      @page.reload
      assert_equal image_2.id, @page.cover.id
      assert_equal 0, @page.atoms.count

      image_1.destroy!

      audit = @page.audits.first
      revision = audit.revision
      revision.reconstruct_folio_audited_data(audit:)
      revision.save!

      @page.reload

      # keeps the image_2 cover as image_1 is deleted
      assert_equal "v1", @page.title
      assert_equal image_2.id, @page.cover.id
      assert_equal "Folio::Atom::Audited::Invalid", @page.atoms.first.type
    end
  end

  test "atoms while skipping a step" do
    Audited.stub(:auditing_enabled, true) do
      site = get_any_site

      @page = AuditedPage.create(title: "v1",
                                 site:)

      @page.update!(title: "v2",
                    atoms_attributes: {
                      0 => {
                        type: "Dummy::Atom::Contents::Text",
                        position: 1,
                        content: "atom 1 v1"
                      }
                    })

      @page.update!(title: "v3")

      assert_equal 3, @page.revisions.size

      @page.audits.first

      v1_audit = @page.audits.first
      v1_revision = v1_audit.revision
      v1_revision.reconstruct_folio_audited_data(audit: v1_audit)
      v1_revision.save!

      @page.reload

      assert_equal "v1", @page.title
      assert_equal 0, @page.atoms.count
    end
  end

  test "saving with atoms doesn't create unnecessary revisions" do
    Audited.stub(:auditing_enabled, true) do
      site = get_any_site

      @page = AuditedPage.create(title: "v1",
                                 site:,
                                 atoms_attributes: {
                                  0 => {
                                    type: "Dummy::Atom::Contents::Text",
                                    position: 1,
                                    content: "atom 1 v1"
                                  }
                                })

      assert_equal 1, @page.revisions.count
      @page.reload

      assert_difference -> { @page.revisions.count }, 0 do
        # saving with the same content shouldn't create another audit
        @page.update!(atoms_attributes: { 0 => { id: @page.atoms.first.id, content: "atom 1 v1" } })
      end
    end
  end

  test "sets atom cover_placement id" do
    Audited.stub(:auditing_enabled, true) do
      site = get_any_site
      image_one = create(:folio_file_image, site:)
      image_two = create(:folio_file_image, site:)

      page = AuditedPage.create!(title: "v1",
                                 site:,
                                 atoms_attributes: { 0 => { type: "Dummy::Atom::Images::SingleImage", position: 1, cover_placement_attributes: { file_id: image_one.id } } })

      first_atom_id = page.atoms.first.id

      audit = page.audits.last

      assert_equal first_atom_id, audit.folio_data["atoms"]["atoms"][0]["id"]
      assert_equal page.atoms.first.cover_placement.id, audit.folio_data["atoms"]["atoms"][0]["_file_placements"]["cover_placement"]["id"]
      assert_equal image_one.id, audit.folio_data["atoms"]["atoms"][0]["_file_placements"]["cover_placement"]["file_id"]

      page.update!(atoms_attributes: { 0 => { id: first_atom_id, cover_placement_attributes: { file_id: image_two.id } } })

      audit = page.audits.last

      assert_equal first_atom_id, audit.folio_data["atoms"]["atoms"][0]["id"]
      assert_equal page.atoms.first.cover_placement.id, audit.folio_data["atoms"]["atoms"][0]["_file_placements"]["cover_placement"]["id"]
      assert_equal image_two.id, audit.folio_data["atoms"]["atoms"][0]["_file_placements"]["cover_placement"]["file_id"]

      audit = page.audits.first
      revision = audit.revision
      revision.reconstruct_folio_audited_data(audit:)
      revision.save!

      page.reload

      assert_equal first_atom_id, page.atoms.first.id
      assert_equal image_one.id, page.atoms.first.cover_placement.file_id
    end
  end

  test "handles type" do
    Audited.stub(:auditing_enabled, true) do
      site = get_any_site

      page = AuditedPage.create!(title: "v1", site:)
      first_audit = page.audits.last

      assert_equal "Folio::AuditedTest::AuditedPage", first_audit.audited_changes["type"]

      page = page.becomes!(AuditedPageTwo)
      page.save!
      audit = page.audits.last

      page = Folio::Page.find(page.id)

      assert_equal "Folio::AuditedTest::AuditedPageTwo", page.type
      assert_equal "Folio::AuditedTest::AuditedPageTwo", page.class.name
      assert_equal ["Folio::AuditedTest::AuditedPage", "Folio::AuditedTest::AuditedPageTwo"], audit.audited_changes["type"]

      revision = first_audit.revision
      revision.reconstruct_folio_audited_data(audit: first_audit)
      revision.save!

      page = Folio::Page.find(page.id)
      assert_equal "Folio::AuditedTest::AuditedPage", page.type
      assert_equal "Folio::AuditedTest::AuditedPage", page.class.name
    end
  end

  test "conditional auditing" do
    Audited.stub(:auditing_enabled, true) do
      site = get_any_site

      page = AuditedPageTwo.new(title: "no audit", site:)

      assert_difference -> { page.audits.count }, 0 do
        page.save!
        page.update!(perex: "v2")
      end

      assert_difference -> { page.audits.count }, 1 do
        page.update!(perex: "v3", title: "do audit please")
      end
    end
  end

  test "reconstruct deletes unwanted attachments" do
    Audited.stub(:auditing_enabled, true) do
      site = get_any_site

      image_1 = create(:folio_file_image)

      @page = AuditedPage.create(title: "v1",
                                 site:,
                                 atoms_attributes: { 0 => { type: "Dummy::Atom::Cards::Small", position: 1, title: "foo"  } })

      @page.update!(title: "v2",
                    cover_placement_attributes: { file_id: image_1.id },
                    atoms_attributes: { 0 => { id: @page.atoms.first.id, cover_placement_attributes: { file_id: image_1.id } } })

      assert_equal 2, @page.revisions.count

      assert_equal image_1.id, @page.cover_placement.file_id
      assert_equal image_1.id, @page.atoms.first.cover_placement.file_id

      first_audit = @page.audits.first
      revision = first_audit.revision
      revision.reconstruct_folio_audited_data(audit: first_audit)
      revision.save!

      @page.reload

      assert_equal "v1", @page.title
      assert_nil @page.cover_placement
      assert_nil @page.atoms.reload.first.cover_placement
    end
  end
end
