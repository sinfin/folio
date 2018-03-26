# frozen_string_literal: true

module Folio
  class FilePlacement < ApplicationRecord
    include Taggable
    include PregenerateThumbnails

    # Relations
    belongs_to :file, class_name: 'Folio::File'
    belongs_to :placement,
               polymorphic: true,
               # so that validations work https://stackoverflow.com/a/39114379/910868
               optional: true

    # only one tag allowed
    validate :allowed_tag

    # Scopes
    scope :with_image,    -> { joins(:file).where("folio_files.type = 'Folio::Image'") }
    scope :with_document, -> { joins(:file).where("folio_files.type = 'Folio::Document'") }
    scope :ordered,       -> { order(position: :asc) }

    # Override in main app
    def self.tags_for_select
      []
    end

    def self.options_for_tag_select
      self.tags_for_select.map do |tag|
        [I18n.t("folio.file_placement.tags.#{tag}"), tag]
      end
    end

    # FIXME acts as taggable bug: tag_list_changed? doesn't work :(
    def tag_list=(values)
      updated_at_will_change! if self.file.type == 'Folio::Document'
      super(values)
    end

    private

      def allowed_tag
        if self.tag_list.present?
          errors.add(:model, 'only one tag is allowed') if self.tag_list.count != 1

          if Folio::FilePlacement.tags_for_select.exclude?(self.tag_list.first)
            errors.add(:model, 'is not included in tags_for_select list')
          end
        end
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
