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

      atom_1 = create(:folio_atom, node: node, position: 1)
      node.reload

      assert_equal([atom_1], node.atoms.to_a)
      assert_equal([[nil, [atom_1]]], node.atoms_in_molecules)

      test_atom_1 = TestAtom.create!(title: 'foo',
                                     position: 2,
                                     node: node)
      test_atom_2 = TestAtom.create!(title: 'bar',
                                     position: 3,
                                     node: node)

      atom_2 = create(:folio_atom, node: node, position: 4)

      node.reload

      assert_equal([atom_1, test_atom_1, test_atom_2, atom_2],
                   node.atoms.to_a)
      assert_equal([
        [nil, [atom_1]],
        [TestMolecule, [test_atom_1, test_atom_2]],
        [nil, [atom_2]],
      ], node.atoms_in_molecules)

      name_atom_1 = TestMoleculeNameAtom.create!(title: 'foo',
                                                 node: node,
                                                 position: 5)
      name_atom_2 = TestMoleculeNameAtom.create!(title: 'bar',
                                                 node: node,
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
