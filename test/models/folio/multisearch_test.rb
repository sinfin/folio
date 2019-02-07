# frozen_string_literal: true

require 'test_helper'

class Folio::MultisearchTest < ActiveSupport::TestCase
  test 'pages' do
    search = PgSearch.multisearch('foo')
    assert search.blank?

    page = create(:folio_page, title: 'foo bar')

    search = PgSearch.multisearch('foo')
    assert_equal(1, search.size)
    assert_equal(page.id, search.first.searchable.id)
  end

  test 'atoms' do
    search = PgSearch.multisearch('foo')
    assert search.blank?

    page = create(:folio_page, title: 'foo bar')
    create_atom(content: 'lorem', placement: page)
    create_atom(content: 'ipsum', placement: page)

    PgSearch::Multisearch.rebuild(Folio::Page)

    search = PgSearch.multisearch('lorem')
    assert_equal(1, search.size)
    assert_equal(page.id, search.first.searchable.id)
  end
end
