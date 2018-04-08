# frozen_string_literal: true

require 'test_helper'

module Folio
  module Atom
    class BaseTest < ActiveSupport::TestCase
      test 'clears stuff when type changes' do
        atom = create(:folio_atom, content: 'foo')
        assert_equal 'foo', atom.content
        assert_equal 0, atom.images.count

        image = create(:folio_image)

        assert atom.update!(type: 'Atom::Gallery',
                            file_placements_attributes: [{
                              file_id: image.id,
                            }])

        assert_equal 'Atom::Gallery', atom.type
        assert_nil atom.content
        assert_equal 1, atom.images.count

        page = create(:folio_page)
        assert atom.update!(type: 'Atom::PageReference',
                            model: page)

        assert_nil atom.content
        assert_equal 0, atom.images.count
        assert_equal page, atom.model
      end

      test 'model_type validation' do
        lead = create(:folio_lead)
        atom = ::Atom::PageReference.new(model: lead)
        refute atom.valid?
        assert_equal([I18n.t('errors.messages.invalid')],
                     atom.errors[:model_type])

        page = create(:folio_page)
        atom.model = page
        assert atom.valid?
        assert atom.save!
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
