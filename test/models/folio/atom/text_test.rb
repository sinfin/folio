# frozen_string_literal: true

require 'test_helper'
require 'folio/atom'

module Folio
  module Atom
    class TextTest < ActionDispatch::IntegrationTest
      include Engine.routes.url_helpers

      test 'renders' do
        create(:folio_site)

        atom = create_atom(title: 'foo',
                           content: '<p>bar</p>',
                           placement: create(:folio_page, title: 'cat'))
        visit page_path(atom.placement, locale: :cs)
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
#  model_type     :string
#  model_id       :integer
#  title          :string
#
# Indexes
#
#  index_folio_atoms_on_model_type_and_model_id          (model_type,model_id)
#  index_folio_atoms_on_placement_type_and_placement_id  (placement_type,placement_id)
#
