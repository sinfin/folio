# frozen_string_literal: true

module Folio
  class Atom < ApplicationRecord
    include HasAttachments

    belongs_to :placement, polymorphic: true
    alias_attribute :node, :placement

    scope :ordered, -> { order(position: :asc) }

    def cell_name
      nil
    end

    def partial_name
      model_name.element
    end

    def data
      self
    end

    # override in subclasses
    def self.form
      false
    end
  end
end

if Rails.env.development?
  Dir["#{Folio::Engine.root}/app/models/folio/atom/*.rb", 'app/models/atom/*.rb'].each do |file|
    require_dependency file
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
