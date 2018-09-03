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
      node = create(:folio_node)

      assert_equal([], node.atoms)
      assert_equal([], node.atoms_in_molecules)

      atom_1 = create_atom(position: 1, placement: node)
      node.reload

      assert_equal([atom_1], node.atoms.to_a)
      assert_equal([[nil, [atom_1]]], node.atoms_in_molecules)

      test_atom_1 = create_atom(TestAtom, title: 'foo',
                                          position: 2,
                                          placement: node)
      test_atom_2 = create_atom(TestAtom, title: 'bar',
                                          position: 3,
                                          placement: node)

      atom_2 = create(:folio_atom, placement: node, position: 4)

      node.reload

      assert_equal([atom_1, test_atom_1, test_atom_2, atom_2],
                   node.atoms.to_a)
      assert_equal([
        [nil, [atom_1]],
        [TestMolecule, [test_atom_1, test_atom_2]],
        [nil, [atom_2]],
      ], node.atoms_in_molecules)

      name_atom_1 = create_atom(TestMoleculeNameAtom, title: 'foo',
                                                      placement: node,
                                                      position: 5)
      name_atom_2 = create_atom(TestMoleculeNameAtom, title: 'bar',
                                                      placement: node,
                                                      position: 6)

      node.reload

      assert_equal([atom_1,
                   test_atom_1, test_atom_2,
                   atom_2,
                   name_atom_1, name_atom_2],
                   node.atoms.to_a)
      assert_equal([
        [nil, [atom_1]],
        [TestMolecule, [test_atom_1, test_atom_2]],
        [nil, [atom_2]],
        ['bar', [name_atom_1, name_atom_2]],
      ], node.atoms_in_molecules)
    end
  end
end
