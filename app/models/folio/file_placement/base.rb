# frozen_string_literal: true

class Folio::FilePlacement::Base < Folio::ApplicationRecord
  include Folio::Taggable
  include PgSearch::Model

  self.table_name = 'folio_file_placements'

  scope :ordered, -> { order(position: :asc) }

  validates :type,
            presence: true

  after_save :extract_placement_title_and_type
  after_touch :extract_placement_title_and_type

  def to_label
    title.presence || file.try(:file_name) || 'error: empty file'
  end

  def self.folio_file_placement(class_name, name = nil)
    belongs_to :file, class_name: class_name,
                      inverse_of: :file_placements,
                      required: true

    belongs_to :placement, polymorphic: true,
                           inverse_of: name,
                           required: true,
                           touch: true
  end

  def self.folio_image_placement(name = nil)
    include Folio::PregenerateThumbnails
    folio_file_placement('Folio::Image', name)
    self.class_eval { alias :image :file }
  end

  def self.folio_document_placement(name = nil)
    folio_file_placement('Folio::Document', name)
  end

  private

    def extract_placement_title_and_type
      if placement.present?
        if placement.class < Folio::Atom::Base
          source = placement.placement
        else
          source = placement
        end

        I18n.with_locale(Rails.application.config.folio_console_locale) do
          title = source.try(:to_label) ||
                  source.try(:title) ||
                  source.try(:name)

          pl_title = [source.class.model_name.human, title].join(' - ')

          if title.present?
            update_columns(placement_title: pl_title,
                           placement_title_type: source.class.to_s)
          end
        end
      end
    end
end

# == Schema Information
#
# Table name: folio_file_placements
#
#  id                   :bigint(8)        not null, primary key
#  placement_type       :string
#  placement_id         :bigint(8)
#  file_id              :bigint(8)
#  position             :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  type                 :string
#  title                :text
#  alt                  :string
#  placement_title      :string
#  placement_title_type :string
#
# Indexes
#
#  index_folio_file_placements_on_file_id                          (file_id)
#  index_folio_file_placements_on_placement_title                  (placement_title)
#  index_folio_file_placements_on_placement_title_type             (placement_title_type)
#  index_folio_file_placements_on_placement_type_and_placement_id  (placement_type,placement_id)
#  index_folio_file_placements_on_type                             (type)
#
