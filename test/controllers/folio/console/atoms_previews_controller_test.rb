# frozen_string_literal: true

require 'test_helper'

class Folio::Console::AtomsPreviewsControllerTest < Folio::Console::BaseControllerTest
  test 'show' do
    folio_page = create(:folio_page)
    create_atom(Folio::Atom::Text, placement: folio_page,
                                   content: 'foo')
    create_atom(Dummy::Atom::DaVinci, placement: folio_page,
                                      text: 'DaVinci text',
                                      string: 'DaVinci string',
                                      cover: create(:folio_image))
    create_atom(Folio::Atom::Text, placement: folio_page,
                                   content: 'bar')

    ids = folio_page.reload.all_atoms_in_array
    visit console_atoms_preview_path(ids: ids)
    atoms = page.find_all('.f-c-atoms-previews__atom')
    assert_equal(3, atoms.size)
    assert_equal('atoms', atoms[0].native['data-root-key'])
    assert_equal('0', atoms[0].native['data-index'])
  end
end
