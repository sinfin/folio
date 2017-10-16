# frozen_string_literal: true

module Folio
  class Atom < ApplicationRecord
    belongs_to :node

    has_many :file_placements, -> { ordered }, class_name: 'Folio::FilePlacement', as: :placement, dependent: :destroy
    has_many :files, through: :file_placements
    has_many :images, source: :file, through: :file_placements
    has_many :documents, source: :file, through: :file_placements

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
#  id         :integer          not null, primary key
#  type       :string
#  node_id    :integer
#  content    :text
#  position   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_folio_atoms_on_node_id  (node_id)
#
