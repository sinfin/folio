# frozen_string_literal: true

require 'test_helper'

module Folio
  class FilePlacementTest < ActiveSupport::TestCase
    class MyAtom < ::Folio::Atom::Base
      STRUCTURE = {
        cover: true,
      }
    end

    test 'placement_title' do
      node = create(:folio_node, title: 'foo')
      node.cover = create(:folio_image)

      # works
      assert_equal('foo', node.cover_placement.placement_title)

      # updates through touch
      node.update!(title: 'bar')
      assert_equal('bar', node.cover_placement.reload.placement_title)

      # works for atoms
      atom = create_atom(MyAtom, :cover, placement: node)
      assert_equal('bar', atom.cover_placement.placement_title)
    end
  end
end

# == Schema Information
#
# Table name: folio_file_placements
#
#  id             :integer          not null, primary key
#  placement_type :string
#  placement_id   :integer
#  file_id        :integer
#  caption        :string
#  position       :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_folio_file_placements_on_file_id                          (file_id)
#  index_folio_file_placements_on_placement_type_and_placement_id  (placement_type,placement_id)
#
