# frozen_string_literal: true

class Folio::FilePlacement::Base < Folio::ApplicationRecord
  include Folio::Taggable
  include PgSearch::Model

  self.table_name = "folio_file_placements"

  scope :ordered, -> { order(position: :asc) }

  validates :type,
            presence: true

  validate :validate_attribution_if_needed
  validate :validate_alt_if_needed
  validate :validate_description_if_needed

  after_save :run_after_save_job!
  after_touch :run_after_save_job!
  after_create :run_file_after_save_job!
  after_destroy :run_file_after_save_job!

  before_create :imprint_file_texts

  attr_accessor :dont_run_after_save_jobs

  def to_label
    title.presence || file.try(:file_name) || "error: empty file"
  end

  def self.folio_file_placement(class_name, name = nil, allow_embed: false)
    belongs_to :file, class_name:,
                      inverse_of: :file_placements,
                      required: allow_embed ? false : true

    belongs_to :placement, polymorphic: true,
                           inverse_of: name,
                           required: false,
                           touch: true

    if allow_embed
      define_method :folio_html_sanitization_config do
        {
          enabled: true,
          attributes: {
            folio_embed_data: :unsafe_html,
          }
        }
      end

      validate :validate_file_or_embed
    end
  end

  def self.folio_image_placement(name = nil, allow_embed: false)
    include Folio::PregenerateThumbnails
    folio_file_placement("Folio::File::Image", name, allow_embed:)
    self.class_eval { alias :image :file }
  end

  def self.folio_document_placement(name = nil)
    folio_file_placement("Folio::File::Document", name)
  end

  def run_after_save_job!
    return if dont_run_after_save_jobs
    return if ENV["SKIP_FOLIO_FILE_AFTER_SAVE_JOB"]
    return if Rails.env.test? && !Rails.application.config.try(:folio_testing_after_save_job)

    if file_id_changed?
      previous_file = Folio::File.find_by(id: file_id_was)

      if previous_file
        previous_file.run_after_save_job
      end

      if file
        file.run_after_save_job
      end
    end

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

  def self.non_nillifiable_fields
    %w[alt title description]
  end

  def alt_with_fallback
    if alt.nil?
      file.try(:alt)
    else
      alt
    end
  end

  def description_with_fallback
    if description.nil?
      file.try(:description)
    else
      description
    end
  end

  def validate_attribution_if_needed
    return unless Rails.application.config.folio_files_require_attribution
    return if errors[:file].present? && errors[:file].include?(:missing_file_attribution)
    return if file.blank?
    return if placement && !placement.should_validate_file_placements_attribution_if_needed?

    if file.author.blank? && file.attribution_source.blank? && file.attribution_source_url.blank?
      errors.add(:file, :missing_file_attribution)
    end
  end

  def validate_alt_if_needed
    return unless Rails.application.config.folio_files_require_alt
    return if errors[:file].present? && errors[:file].include?(:missing_file_alt)
    return if file.blank?
    return if placement && !placement.should_validate_file_placements_alt_if_needed?

    if file.class.human_type == "image" && alt_with_fallback.blank?
      errors.add(:file, :missing_file_alt)
    end
  end

  def validate_description_if_needed
    return unless Rails.application.config.folio_files_require_description
    return if errors[:file].present? && errors[:file].include?(:missing_file_description)
    return if file.blank?
    return if placement && !placement.should_validate_file_placements_description_if_needed?

    if file.description.blank?
      errors.add(:file, :missing_file_description)
    end
  end

  private
    def validate_file_or_embed
      if folio_embed_data.present? && folio_embed_data["active"] == true
        Folio::Embed.validate_record(record: self,
                                     attribute_name: :folio_embed_data)
      else
        if file.blank?
          errors.add(:file, :blank)
        end
      end
    end

    def imprint_file_texts
      return if !title.nil? && !alt.nil? && !description.nil?
      return if file.blank?

      if title.nil?
        self.title = file.headline.presence
      end

      if alt.nil?
        self.alt = file.alt.presence
      end

      if description.nil?
        self.description = file.description.presence
      end
    end
end

# == Schema Information
#
# Table name: folio_file_placements
#
#  id                   :integer          not null, primary key
#  placement_type       :string
#  placement_id         :integer
#  file_id              :integer
#  position             :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  type                 :string
#  title                :text
#  alt                  :string
#  placement_title      :string
#  placement_title_type :string
#  folio_embed_data     :jsonb
#  description          :text
#
# Indexes
#
#  index_folio_file_placements_on_file_id                          (file_id)
#  index_folio_file_placements_on_placement_title                  (placement_title)
#  index_folio_file_placements_on_placement_title_type             (placement_title_type)
#  index_folio_file_placements_on_placement_type_and_placement_id  (placement_type,placement_id)
#  index_folio_file_placements_on_type                             (type)
#
