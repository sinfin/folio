# frozen_string_literal: true

require 'test_helper'

module Folio
  class ReferencedFromAtomsTest < ActiveSupport::TestCase
    class MenuWithAtoms < Menu
      include ReferencedFromAtoms
    end

    class TestAtom < Atom::Base
      STRUCTURE = { model: [MenuWithAtoms] }
    end

    test 'deletes reference atoms' do
      menu = MenuWithAtoms.create!(locale: :cs)
      create_atom(TestAtom, model: menu)
      assert_equal(1, Atom::Base.count)

      assert menu.destroy!
      assert_equal(0, Atom::Base.count)
    end
  end
end
