# frozen_string_literal: true

require 'test_helper'

module Folio
  class MultisearchTest < ActiveSupport::TestCase
    test 'nodes' do
      search = PgSearch.multisearch('foo')
      assert search.blank?

      node = create(:folio_node_with_atoms, atoms_count: 2,
                                            content: 'foo bar')

      search = PgSearch.multisearch('foo')
      assert_equal(1, search.size)
      assert_equal(node.id, search.first.searchable.id)
    end

    test 'atoms' do
      search = PgSearch.multisearch('foo')
      assert search.blank?

      node = create(:folio_node_with_atoms, atoms_count: 2,
                                            content: 'foo bar')

      node.atoms.first.update!(content: 'lorem')
      node.atoms.second.update!(content: 'ipsum')

      PgSearch::Multisearch.rebuild(Folio::Node)

      search = PgSearch.multisearch('lorem')
      assert_equal(1, search.size)
      assert_equal(node.id, search.first.searchable.id)
    end
  end
end
