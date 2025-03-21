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
end
