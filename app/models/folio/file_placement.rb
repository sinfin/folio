# frozen_string_literal: true

module Folio
  class FilePlacement < ApplicationRecord
    # Relations
    belongs_to :file, class_name: 'Folio::File'
    belongs_to :placement, polymorphic: true

    # Scopes
    scope :with_image,    -> { joins(:file).where("folio_files.type = 'Folio::Image'") }
    scope :with_document, -> { joins(:file).where("folio_files.type = 'Folio::Document'") }
    scope :ordered,       -> { order(position: :asc) }
  end
end

# == Schema Information
#
# Table name: folio_file_placements
#
#  id         :integer          not null, primary key
#  node_id    :integer
#  file_id    :integer
#  caption    :string
#  position   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_folio_file_placements_on_file_id  (file_id)
#  index_folio_file_placements_on_node_id  (node_id)
#
