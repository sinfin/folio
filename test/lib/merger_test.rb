# frozen_string_literal: true

require "test_helper"

class Folio::MergerTest < ActiveSupport::TestCase
  class ReferenceAtom < Folio::Atom::Base
    ASSOCIATIONS = {
      page: %w[Folio::Page]
    }
  end

  test "Folio::PageMerger" do
    original = create(:folio_page, title: "foo", slug: "foo")
    original_atom = create_atom(Dummy::Atom::Text, :content, placement: original)
    original_cover = create(:folio_cover_placement, placement: original)

    duplicate = create(:folio_page, title: "bar", slug: "bar")
    duplicate_atom = create_atom(Dummy::Atom::Text, :content, placement: duplicate)
    duplicate_cover = create(:folio_cover_placement, placement: duplicate)

    merger = Folio::Page::Merger.new(original, duplicate)

    reference = create_atom(ReferenceAtom, page: duplicate)
    assert_equal(duplicate.id, reference.page.id)

    merger.merge!( # info: receipt how to merge these two
      title: Folio::Merger::DUPLICATE,
      slug: Folio::Merger::ORIGINAL,
      atoms: Folio::Merger::DUPLICATE,
      cover_placement: Folio::Merger::DUPLICATE,
    )

    assert_equal("bar", original.reload.title)
    assert_not(Folio::Page.exists?(id: duplicate.id))

    assert_not(Folio::Atom::Base.exists?(id: original_atom.id))
    assert_equal(original.id, duplicate_atom.reload.placement_id)

    assert_not(Folio::FilePlacement::Base.exists?(id: original_cover.id))
    assert_equal(original.id, duplicate_cover.reload.placement_id)

    assert_equal(original, reference.reload.page)
  end
end
