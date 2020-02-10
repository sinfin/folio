# frozen_string_literal: true

require 'test_helper'

class Folio::MergerTest < ActiveSupport::TestCase
  test 'Folio::PageMerger' do
    original = create(:folio_page, title: 'foo', slug: 'foo')
    original_atom = create_atom(Folio::Atom::Text, :content, placement: original)
    original_cover = create(:folio_cover_placement, placement: original)
    duplicate = create(:folio_page, title: 'bar', slug: 'bar')
    duplicate_atom = create_atom(Folio::Atom::Text, :content, placement: duplicate)
    duplicate_cover = create(:folio_cover_placement, placement: duplicate)
    merger = Folio::Page::Merger.new(original, duplicate)

    merger.merge!(
      title: Folio::Merger::DUPLICATE,
      slug: Folio::Merger::ORIGINAL,
      atoms: Folio::Merger::DUPLICATE,
      cover_placement: Folio::Merger::DUPLICATE,
    )

    assert_equal('bar', original.reload.title)
    assert_not(Folio::Page.exists?(id: duplicate.id))

    assert_not(Folio::Atom::Base.exists?(id: original_atom.id))
    assert_equal(original.id, duplicate_atom.reload.placement_id)

    assert_not(Folio::FilePlacement::Base.exists?(id: original_cover.id))
    assert_equal(original.id, duplicate_cover.reload.placement_id)
  end
end
