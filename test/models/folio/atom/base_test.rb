# frozen_string_literal: true

require 'test_helper'

class Folio::Atom::BaseTest < ActiveSupport::TestCase
  class PageReferenceAtom < Folio::Atom::Base
    ASSOCIATIONS = {
      page: %i[Folio::Page]
    }
  end

  test 'associations' do
    page = create(:folio_page)
    atom1 = PageReferenceAtom.create!(page: page, placement: page)
    assert_equal(atom1.page, page)
    assert_equal(page.id, atom1.page_id)

    atom2 = PageReferenceAtom.create!(page_type: page.class.name,
                                      page_id: page.id,
                                      placement: page)
    assert_equal(atom2.page, page)
    assert_equal(page.id, atom2.page_id)
  end
end
