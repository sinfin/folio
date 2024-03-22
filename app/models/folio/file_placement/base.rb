# frozen_string_literal: true

class Folio::FilePlacement::Base < Folio::ApplicationRecord
  include Folio::Taggable
  include PgSearch::Model

  self.table_name = "folio_file_placements"

  scope :ordered, -> { order(position: :asc) }

  validates :type,
            presence: true

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
#  index_folio_file_placements_on_file_id               (file_id)
#  index_folio_file_placements_on_placement             (placement_type,placement_id)
#  index_folio_file_placements_on_placement_title       (placement_title)
#  index_folio_file_placements_on_placement_title_type  (placement_title_type)
#  index_folio_file_placements_on_type                  (type)
#
