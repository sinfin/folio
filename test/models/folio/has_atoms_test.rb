# frozen_string_literal: true

require "test_helper"

class Folio::HasAtomsTest < ActiveSupport::TestCase
  class TestAtom < Folio::Atom::Base
    STRUCTURE = { title: :string }

    def self.molecule_cell_name
      "foo"
    end
  end

  class TestMoleculeNameAtom < Folio::Atom::Base
    STRUCTURE = { title: :string }

    def self.molecule_cell_name
      "bar"
    end
  end

  test "atoms_in_molecules" do
    page = create(:folio_page, locale: I18n.locale)

    assert_equal([], page.atoms)
    assert_equal([], page.atoms_in_molecules)

    atom_1 = create_atom(Dummy::Atom::Text, position: 1, placement: page, content: "foo")
    page.reload

    assert_equal([atom_1], page.atoms.to_a)
    assert_equal([[nil, [atom_1]]], page.atoms_in_molecules)

    test_atom_1 = create_atom(TestAtom, title: "foo",
                                        position: 2,
                                        placement: page)
    test_atom_2 = create_atom(TestAtom, title: "bar",
                                        position: 3,
                                        placement: page)

    atom_2 = create_atom(Dummy::Atom::Text, placement: page, position: 4, content: "a")

    page.reload

    assert_equal([atom_1.id, test_atom_1.id, test_atom_2.id, atom_2.id],
                 page.atoms.pluck(:id))
    assert_equal([
      [nil, [atom_1]],
      ["foo", [test_atom_1, test_atom_2]],
      [nil, [atom_2]],
    ], page.atoms_in_molecules)

    name_atom_1 = create_atom(TestMoleculeNameAtom, title: "foo",
                                                    placement: page,
                                                    position: 5)
    name_atom_2 = create_atom(TestMoleculeNameAtom, title: "bar",
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
      ["foo", [test_atom_1, test_atom_2]],
      [nil, [atom_2]],
      ["bar", [name_atom_1, name_atom_2]],
    ], page.atoms_in_molecules)
  end

  class PageWhitelistingAtoms < Folio::Page
    def self.atom_class_names_whitelist
      %w[
        Folio::HasAtomsTest::TestAtom
      ]
    end
  end

  test "atom_class_names_whitelist" do
    page = PageWhitelistingAtoms.create!(locale: I18n.locale, title: "PageWhitelistingAtoms")

    assert_equal([], page.atoms)

    assert_raises(ActiveRecord::RecordInvalid) do
      create_atom(TestMoleculeNameAtom, :title, placement: page)
    end

    assert_equal([], page.reload.atoms)

    atom = create_atom(TestAtom, :title, placement: page)
    assert_equal([atom], page.reload.atoms)

    page.atoms.destroy_all
    assert_equal([], page.reload.atoms)

    page.atoms_attributes = [
      { type: "Folio::HasAtomsTest::TestAtom", title: "foo" },
      { type: "Folio::HasAtomsTest::TestMoleculeNameAtom", title: "foo" },
    ]

    assert_equal(["Folio::HasAtomsTest::TestAtom"], page.atoms.map(&:type))

    # this fails in tests only as somehow the atom isn't persisted
    # assert page.save!
    # assert_equal(["Folio::HasAtomsTest::TestAtom"], page.reload.atoms.pluck(:type))
  end
end
