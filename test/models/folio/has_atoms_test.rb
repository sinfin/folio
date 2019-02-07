# frozen_string_literal: true

require 'test_helper'

module Folio
  class HasAtomsTest < ActiveSupport::TestCase
    class TestMolecule < Molecule::Base
      def self.cell_name
        'foo'
      end
    end

    class TestAtom < Atom::Base
      STRUCTURE = { title: :string }

      def self.molecule
        TestMolecule
      end
    end

    class TestMoleculeNameAtom < Atom::Base
      STRUCTURE = { title: :string }

      def self.molecule_cell_name
        'bar'
      end
    end

    test 'atoms_in_molecules' do
      page = create(:folio_page)

      assert_equal([], page.atoms)
      assert_equal([], page.atoms_in_molecules)

      atom_1 = create_atom(position: 1, placement: page)
      page.reload

      assert_equal([atom_1], page.atoms.to_a)
      assert_equal([[nil, [atom_1]]], page.atoms_in_molecules)

      test_atom_1 = create_atom(TestAtom, title: 'foo',
                                          position: 2,
                                          placement: page)
      test_atom_2 = create_atom(TestAtom, title: 'bar',
                                          position: 3,
                                          placement: page)

      atom_2 = create(:folio_atom, placement: page, position: 4)

      page.reload

      assert_equal([atom_1, test_atom_1, test_atom_2, atom_2],
                   page.atoms.to_a)
      assert_equal([
        [nil, [atom_1]],
        [TestMolecule, [test_atom_1, test_atom_2]],
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
        [TestMolecule, [test_atom_1, test_atom_2]],
        [nil, [atom_2]],
        ['bar', [name_atom_1, name_atom_2]],
      ], page.atoms_in_molecules)
    end
  end
end
