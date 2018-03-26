# frozen_string_literal: true

module Folio
  class CoverPlacement < ApplicationRecord
    # Relations
    belongs_to :file,
               class_name: 'Folio::File',
               required: true
    belongs_to :placement,
               polymorphic: true,
               # so that validations work
               # see https://stackoverflow.com/a/39114379/910868
               optional: true
  end
end

# == Schema Information
#
# Table name: folio_cover_placements
#
#  id             :integer          not null, primary key
#  placement_type :string
#  placement_id   :integer
#  file_id        :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_folio_cover_placements_on_file_id                          (file_id)
#  index_folio_cover_placements_on_placement_type_and_placement_id  (placement_type,placement_id)
#
