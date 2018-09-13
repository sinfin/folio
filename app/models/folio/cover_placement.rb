# frozen_string_literal: true

module Folio
  class CoverPlacement < ApplicationRecord
    include PregenerateThumbnails

    # Relations
    belongs_to :file,
               class_name: 'Folio::File',
               required: true
    belongs_to :placement,
               polymorphic: true,
               # so that validations work
               # see https://stackoverflow.com/a/39114379/910868
               optional: true,
               touch: true
  end
end

# == Schema Information
#
# Table name: folio_cover_placements
#
#  id             :bigint(8)        not null, primary key
#  placement_type :string
#  placement_id   :bigint(8)
#  file_id        :bigint(8)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_folio_cover_placements_on_file_id                          (file_id)
#  index_folio_cover_placements_on_placement_type_and_placement_id  (placement_type,placement_id)
#
