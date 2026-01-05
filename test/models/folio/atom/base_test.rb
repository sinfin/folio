# frozen_string_literal: true

require "test_helper"

class Folio::Atom::BaseTest < ActiveSupport::TestCase
  class SpecificSite < Folio::Site
  end

  class SpecificSiteAtom < Folio::Atom::Base
    VALID_SITE_TYPES = [SpecificSite.name]
  end

  class PageReferenceAtom < Folio::Atom::Base
    ASSOCIATIONS = {
      page: %i[Folio::Page]
    }
  end

  test "associations" do
    page = create(:folio_page)
    atom1 = PageReferenceAtom.create!(page:, placement: page)
    assert_equal(atom1.page, page)
    assert_equal(page.id, atom1.page_id)

    atom2 = PageReferenceAtom.create!(page_type: page.class.name,
                                      page_id: page.id,
                                      placement: page)
    assert_equal(atom2.page, page)
    assert_equal(page.id, atom2.page_id)
  end

  class SpecialAtomPage < Folio::Page
  end

  class PlacementTestAtom < Folio::Atom::Base
    VALID_PLACEMENT_TYPES = %w[Folio::Atom::BaseTest::SpecialAtomPage]
  end

  test "valid placement types" do
    page = create(:folio_page)

    atom = PlacementTestAtom.new(placement: page)
    assert_not atom.valid?
    assert atom.errors[:placement]

    special_atom_page = create(:folio_page).becomes!(Folio::Atom::BaseTest::SpecialAtomPage)
    special_atom_page.save

    atom = PlacementTestAtom.new(placement: special_atom_page)
    assert atom.valid?
  end

  test "valid placement site types" do
    site = create_site
    placement = create(:folio_page, site:)

    atom = SpecificSiteAtom.new(placement:)
    assert_not atom.valid?
    assert atom.errors[:placement]

    specific_site = create(:folio_site, type: SpecificSite.name)
    specific_site = specific_site.becomes!(SpecificSite)
    specific_site.save!
    placement = create(:folio_page, site: specific_site)

    atom = SpecificSiteAtom.new(placement:)
    assert atom.valid?
  end

  class DeprecatedAtom < Folio::Atom::Base
    STRUCTURE = {
      title: :string,
      legacy_title: :deprecated,
    }
  end

  test "deprecated data" do
    atom = create_atom(DeprecatedAtom, title: "title", legacy_title: "legacy_title")

    assert_equal(atom.title, "title")
    assert_nil(atom.legacy_title)

    atom.update_column(:data, atom.data.merge("legacy_title" => "legacy_title"))

    assert_equal(atom.title, "title")
    assert_equal(atom.legacy_title, "legacy_title")

    atom.update!(title: "title 2", legacy_title: "legacy_title 2")

    assert_equal(atom.title, "title 2")
    assert_nil(atom.legacy_title)
  end

  class UrlJsonAtom < Folio::Atom::Base
    STRUCTURE = {
      url: :url,
      url_json: :url_json,
    }
  end

  test "url and url_json" do
    atom = create_atom(UrlJsonAtom, url: "/foo", url_json: { href: "/foo", rel: "noreferrer", target: "_blank" })

    assert_equal(atom.url, "/foo")

    assert(atom.url_json)
    assert_equal(atom.url_json[:href], "/foo")
    assert_equal(atom.url_json[:rel], "noreferrer")
    assert_equal(atom.url_json[:target], "_blank")
  end

  test "blank url and url_json" do
    atom = create_atom(UrlJsonAtom, url: "", url_json: { href: "", rel: "noreferrer", target: "_blank" })

    assert_nil(atom.url)
    assert_nil(atom.url_json)
  end

  class AtomWithCover < Folio::Atom::Base
    ATTACHMENTS = %i[cover]
  end

  test "should_validate_file_placements methods delegate to placement" do
    page = create(:folio_page, published: true)
    atom = create_atom(AtomWithCover, :cover, placement: page)

    Rails.application.config.stub(:folio_files_require_alt, true) do
      assert atom.should_validate_file_placements_alt_if_needed?
      assert_equal page.should_validate_file_placements_alt_if_needed?, atom.should_validate_file_placements_alt_if_needed?

      page.update_column(:published, false)
      atom.reload
      assert_not atom.should_validate_file_placements_alt_if_needed?

      # Test for_console_form_warning parameter
      assert atom.should_validate_file_placements_alt_if_needed?(for_console_form_warning: true)
    end
  end

  test "should_validate_file_placements methods return false when placement is blank" do
    atom = AtomWithCover.new
    assert_not atom.should_validate_file_placements_alt_if_needed?
  end

  test "atom file placements are validated according to placement rules" do
    page = create(:folio_page, published: true)
    file = create(:folio_file_image, alt: nil)
    atom = create_atom(AtomWithCover, placement: page)
    atom.update!(cover: file)

    Rails.application.config.stub(:folio_files_require_alt, true) do
      assert_not atom.cover_placement.valid?
      assert atom.cover_placement.errors[:alt].present?
    end
  end
end
