# frozen_string_literal: true

require 'test_helper'

class Folio::Console::AtomsControllerTest < Folio::Console::BaseControllerTest
  test 'index' do
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
    visit console_atoms_path(ids: ids)
    atoms = page.find_all('.f-c-atoms-previews__atom')
    assert_equal(3, atoms.size)
    assert_equal('atoms', atoms[0].native['data-root-key'])
    assert_equal('0', atoms[0].native['data-index'])
  end

  test 'preview' do
    post preview_console_atoms_path, params: JSON.parse('{"atoms_attributes":[{"id":1,"type":"Folio::Atom::Text","position":1,"placement_type":"Folio::Page","placement_id":1,"data":null,"content":"lorem ipsum"},{"id":2,"type":"Folio::Atom::Text","position":2,"placement_type":"Folio::Page","placement_id":1,"data":null,"content":"lorem ipsum"},{"id":3,"type":"Folio::Atom::Text","position":3,"placement_type":"Folio::Page","placement_id":1,"data":null,"_destroy":true,"content":"lorem ipsum"}]}')
    assert_response(:ok)
  end

  test 'validate' do
    post validate_console_atoms_path, params: {
      type: 'Dummy::Atom::DaVinci',
      placement_type: 'Folio::Page',
      placement_id: create(:folio_page).id,
    }
    assert_response(:ok)
    json = JSON.parse(response.body)
    assert_equal(false, json['valid'])
    assert_not_nil(json['errors'])
    assert_not_nil(json['messages'])
    assert_equal(['string'], json['errors'].keys)
  end
end
