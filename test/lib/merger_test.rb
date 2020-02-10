# frozen_string_literal: true

require 'test_helper'

class Folio::MergerTest < ActiveSupport::TestCase
  test 'Folio::PageMerger' do
    original = create(:folio_page, title: 'foo', slug: 'foo')
    original_atom = create_atom(Folio::Atom::Text, :content, placement: original)
    duplicate = create(:folio_page, title: 'bar', slug: 'bar')
    duplicate_atom = create_atom(Folio::Atom::Text, :content, placement: duplicate)
    merger = Folio::Page::Merger.new(original, duplicate)

    merger.merge!(
      title: 'duplicate',
      slug: 'original',
      atoms: 'duplicate',
    )

    assert_equal('bar', original.reload.title)
    assert_not(Folio::Page.exists?(id: duplicate.id))
    assert_not(Folio::Atom::Base.exists?(id: original_atom.id))
    assert_equal(original.id, duplicate_atom.reload.placement_id)
  end
end
