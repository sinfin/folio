# frozen_string_literal: true

require 'test_helper'

class Folio::HasAtomsTest < ActiveSupport::TestCase
  class TestAtom < Folio::Atom::Base
    STRUCTURE = { title: :string }

    def self.molecule_cell_name
      'foo'
    end
  end

  class TestMoleculeNameAtom < Folio::Atom::Base
    STRUCTURE = { title: :string }

    def self.molecule_cell_name
      'bar'
    end
  end

  test 'atoms_in_molecules' do
    page = create(:folio_page, locale: I18n.locale)

    assert_equal([], page.atoms)
    assert_equal([], page.atoms_in_molecules)

    atom_1 = create_atom(position: 1, placement: page, content: 'foo')
    page.reload

    assert_equal([atom_1], page.atoms.to_a)
    assert_equal([[nil, [atom_1]]], page.atoms_in_molecules)

    test_atom_1 = create_atom(TestAtom, title: 'foo',
                                        position: 2,
                                        placement: page)
    test_atom_2 = create_atom(TestAtom, title: 'bar',
                                        position: 3,
                                        placement: page)

    atom_2 = create_atom(placement: page, position: 4, content: 'a')

    page.reload

    assert_equal([atom_1.id, test_atom_1.id, test_atom_2.id, atom_2.id],
                 page.atoms.pluck(:id))
    assert_equal([
      [nil, [atom_1]],
      ['foo', [test_atom_1, test_atom_2]],
      [nil, [atom_2]],
    ], page.atoms_in_molecules)

    name_atom_1 = create_atom(TestMoleculeNameAtom, title: 'foo',
                                                    placement: page,
                                                    position: 5)
    name_atom_2 = create_atom(TestMoleculeNameAtom, title: 'bar',
                                                    placement: page,
                                                    position: 6)

    page.reload

    assert_equal([atom_1,
                 test_atom_1, test_atom_2,
                 atom_2,
                 name_atom_1, name_atom_2],
                 page.atoms.to_a)
    assert_equal([
      [nil, [atom_1]],
      ['foo', [test_atom_1, test_atom_2]],
      [nil, [atom_2]],
      ['bar', [name_atom_1, name_atom_2]],
    ], page.atoms_in_molecules)
  end
end
