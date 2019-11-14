# frozen_string_literal: true

require 'test_helper'

class Folio::PageTest < ActiveSupport::TestCase
  # # TODO: test with folio_pages_translations
  # test 'translate a page with atoms' do
  #   page = create(:folio_page, locale: :cs)
  #   create_atom(Folio::Atom::Text, content: 'foo', placement: page)
  #   create_atom(::Atom::Gallery, :images, placement: page)
  #   assert_equal(1, page.atoms.last.images.count)

  #   translation = page.translate!(:en)
  #   assert_equal(translation.atoms.count, 2)

  #   assert_equal('foo', translation.atoms.first.content)
  #   assert_equal(1, translation.atoms.last.images.count)

  #   translation.update!(published: true, published_at: 1.minute.ago)
  #   assert_equal(translation, page.translation(:en))
  # end

  # # TODO: test with folio_pages_ancestry
  # test 'ancestry touch' do
  #   parent = create(:folio_page)
  #   updated_at = parent.updated_at

  #   create(:folio_page, parent: parent)
  #   assert updated_at < parent.reload.updated_at
  # end
end
