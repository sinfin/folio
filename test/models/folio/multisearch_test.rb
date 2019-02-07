# frozen_string_literal: true

require 'test_helper'

class Folio::MultisearchTest < ActiveSupport::TestCase
  test 'pages' do
    search = PgSearch.multisearch('foo')
    assert search.blank?

    page = create(:folio_page_with_atoms, atoms_count: 2,
                                          content: 'foo bar')

    search = PgSearch.multisearch('foo')
    assert_equal(1, search.size)
    assert_equal(page.id, search.first.searchable.id)
  end

  test 'atoms' do
    search = PgSearch.multisearch('foo')
    assert search.blank?

    page = create(:folio_page_with_atoms, atoms_count: 2,
                                          content: 'foo bar')

    page.atoms.first.update!(content: 'lorem')
    page.atoms.second.update!(content: 'ipsum')

    PgSearch::Multisearch.rebuild(Folio.page)

    search = PgSearch.multisearch('lorem')
    assert_equal(1, search.size)
    assert_equal(page.id, search.first.searchable.id)
  end
end
