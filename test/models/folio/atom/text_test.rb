# frozen_string_literal: true

require 'test_helper'

module Folio
  module Atom
    class TextTest < ActionDispatch::IntegrationTest
      include Engine.routes.url_helpers

      test 'renders' do
        atom = create(:folio_atom, title: 'foo',
                                   content: 'bar',
                                   placement: create(:folio_category, title: 'cat'))
        visit category_path(atom.placement, locale: :cs)
        assert_equal('cat', page.find('h1').text)
        assert_equal('bar', page.find('p').text)
      end
    end
  end
end

# == Schema Information
#
# Table name: folio_atoms
#
#  id             :integer          not null, primary key
#  type           :string
#  content        :text
#  position       :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  placement_type :string
#  placement_id   :integer
#
# Indexes
#
#  index_folio_atoms_on_placement_type_and_placement_id  (placement_type,placement_id)
#
