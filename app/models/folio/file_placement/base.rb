# frozen_string_literal: true

class Folio::FilePlacement::Base < Folio::ApplicationRecord
  include Folio::Taggable
  include PgSearch::Model

  self.table_name = "folio_file_placements"

  scope :ordered, -> { order(position: :asc) }

  validates :type,
            presence: true

  validate :validate_file_attribution_and_texts_if_needed

  after_save :run_after_save_job!
  after_touch :run_after_save_job!
  after_create :run_file_after_save_job!
  after_destroy :run_file_after_save_job!

  attr_accessor :dont_run_after_save_jobs

  def to_label
    title.presence || file.try(:file_name) || "error: empty file"
  end

  def self.folio_file_placement(class_name, name = nil)
    belongs_to :file, class_name:,
                      inverse_of: :file_placements,
                      required: true

    belongs_to :placement, polymorphic: true,
                           inverse_of: name,
                           required: false,
                           touch: true
  end

  def self.folio_image_placement(name = nil)
    include Folio::PregenerateThumbnails
    folio_file_placement("Folio::File::Image", name)
    self.class_eval { alias :image :file }
  end

  def self.folio_document_placement(name = nil)
    folio_file_placement("Folio::File::Document", name)
  end

  def run_after_save_job!
    return if dont_run_after_save_jobs
    return if ENV["SKIP_FOLIO_FILE_AFTER_SAVE_JOB"]
    return if Rails.env.test? && !Rails.application.config.try(:folio_testing_after_save_job)

    Folio::FilePlacements::AfterSaveJob.perform_later(self)
  end

  def run_file_after_save_job!
    return if dont_run_after_save_jobs
    return if ENV["SKIP_FOLIO_FILE_AFTER_SAVE_JOB"]

    if file
      file.run_after_save_job
    elsif changed_attributes && changed_attributes["file_id"]
      file_before_destroy = Folio::File.find_by(id: changed_attributes["file_id"])
      file_before_destroy.run_after_save_job if file_before_destroy
    end
  end

  def audited_hash_key_fallback
    reflection = self.class.reflect_on_association(:placement)

    if reflection && reflection.options
      reflection.options[:inverse_of]
    end
  end

  private
    def validate_file_attribution_and_texts_if_needed
      return if file.blank?

      if Rails.application.config.folio_files_require_attribution
        if placement.class.try(:ignore_folio_files_require_attribution) != true
          if file.author.blank? && file.attribution_source.blank? && file.attribution_source_url.blank?
            errors.add(:file, :missing_file_attribution)
          end
        end
      end

      if Rails.application.config.folio_files_require_alt
        if placement.class.try(:ignore_folio_files_require_alt) != true
          if file.class.human_type == "image" && file.alt.blank?
            errors.add(:file, :missing_file_alt)
          end
        end
      end

      if Rails.application.config.folio_files_require_description
        if placement.class.try(:ignore_folio_files_require_description) != true
          if file.description.blank?
            errors.add(:file, :missing_file_description)
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
