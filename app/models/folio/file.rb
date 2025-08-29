# frozen_string_literal: true

class Folio::File < Folio::ApplicationRecord
  include Folio::DragonflyFormatValidation
  include Folio::HasHashId
  include Folio::SanitizeFilename
  include Folio::Taggable
  include Folio::Thumbnails
  include Folio::StiPreload
  include Folio::HasAasmStates
  include Folio::BelongsToSite

  READY_STATE = :ready

  DEFAULT_GRAVITIES = %w[
    center
    east
    north
    south
    west
  ]

  dragonfly_accessor :file do
    after_assign :sanitize_filename
  end

  # Relations
  has_many :file_placements, class_name: "Folio::FilePlacement::Base"
  has_many :placements, through: :file_placements

  # Validations
  validates :file, :type,
            presence: true

  validates :default_gravity,
            inclusion: { in: DEFAULT_GRAVITIES },
            allow_nil: true

  validate :validate_attribution_and_texts_if_needed

  # Scopes
  scope :ordered, -> { order(created_at: :desc) }

  scope :by_placement, -> (placement_title) { order(created_at: :desc) }

  scope :by_used, -> (used) do
    case used
    when true, "true"
      joins(:file_placements)
    when false, "false"
      left_joins(:file_placements).where(folio_file_placements: { id: nil })
    else
      noen
    end
  end

  scope :by_tags, -> (tags) do
    if tags.is_a?(String)
      tagged_with(tags.split(","))
    else
      tagged_with(tags)
    end
  end

  scope :by_file_name, -> (query) do
    by_file_name_for_search(sanitize_filename_for_search(query))
  end

  pg_search_scope :by_file_name_for_search,
                  against: [:file_name_for_search],
                  ignoring: :accents,
                  using: {
                    tsearch: { prefix: true }
                  }

  pg_search_scope :by_placement,
                  associated_against: {
                    file_placements: [:placement_title],
                  },
                  ignoring: :accents,
                  using: {
                    tsearch: { prefix: true }
                  }

  pg_search_scope :by_author,
                  against: [:author],
                  ignoring: :accents,
                  using: {
                    tsearch: { prefix: true }
                  }

  before_validation :set_file_track_duration, if: :file_uid_changed?
  before_validation :set_video_file_dimensions, if: :file_uid_changed?
  before_save :set_file_name_for_search, if: :file_name_changed?
  before_destroy :check_usage_before_destroy
  after_save :run_after_save_job
  after_commit :process!, if: :attached_file_changed?
  after_destroy :destroy_attached_file

  attr_accessor :dont_run_after_save_jobs

  aasm do
    state :unprocessed, initial: true, color: :yellow
    state :processing, color: :orange
    state READY_STATE, color: :green
    state :processing_failed, color: :red

    event :process do
      transitions from: :unprocessed, to: :processing
      transitions from: READY_STATE, to: :processing
      after do
        process_attached_file
        after_process
      end
    end

    event :processing_done do
      transitions from: :processing, to: READY_STATE
      transitions from: READY_STATE, to: READY_STATE
    end

    event :processing_failed do
      transitions from: :processing, to: :processing_failed
    end

    event :reprocess do
      transitions from: READY_STATE, to: :processing
    end
  end


  def title
    file_name
  end

  def file_extension
    if file_mime_type.include?("msword")
      file_name.include?("docx") ? :docx : :doc
    else
      Mime::Type.lookup(file_mime_type).symbol
    end
  end

  def to_h
    {
      thumb: thumbnailable? ? thumb(Folio::Console::FileSerializer::ADMIN_THUMBNAIL_SIZE).url : nil,
      file_size:,
      file_name:,
      type:,
      id:,
    }
  end

  def update_file_placements_size!
    update_columns(file_placements_size: file_placements.count,
                   updated_at: current_time_from_proper_timezone)
  end

  def self.hash_id_additional_classes
    [Folio::PrivateAttachment]
  end

  def self.human_type
    "document"
  end

  def self.sanitize_filename_for_search(string)
    string.to_s.gsub("-", "{d}")
               .gsub("_", "{u}")
  end

  def run_after_save_job
    return if dont_run_after_save_jobs
    # updating placements
    return if ENV["SKIP_FOLIO_FILE_AFTER_SAVE_JOB"]
    return if Rails.env.test? && !Rails.application.config.try(:folio_testing_after_save_job)
    Folio::Files::AfterSaveJob.perform_later(self)
  end

  def process_attached_file
    regenerate_thumbnails if try(:thumbnailable?)
    processing_done!
  end

  def destroy_attached_file
  end

  def after_process
    # override in main app if needed
  end

  def attached_file_changed?
    (saved_changes[:file_uid] || changes[:file_uid]).present?
  end

  def regenerate_thumbnails
    try(:admin_thumb, immediate: true)
    if try(:thumbnail_sizes).is_a?(Hash)
      thumbnail_sizes.keys.each { |t_key| file.thumb(t_key) }
    end
  end

  def thumbnailable?
    false
  end

  def private?
    false
  end

  def self.default_gravities_for_select
    DEFAULT_GRAVITIES.map do |gravity|
      [human_attribute_name("default_gravity/#{gravity}"), gravity]
    end
  end

  def self.react_taggable
    true
  end

  def self.sti_paths
    [
      Folio::Engine.root.join("app/models/folio/file"),
      Rails.root.join("app/models/**/file"),
    ]
  end

  def file_track_duration_in_seconds
    file_track_duration
  end

  def screenshot_time_in_ffmpeg_format
    if file_track_duration
      # For videos under 10 seconds: use 1/4 duration (current behavior)
      # For videos 10+ seconds: use fixed 10 seconds (avoids long FFmpeg seeks)
      screenshot_time = if file_track_duration < 10
        file_track_duration / 4.0
      else
        10
      end

      seconds = screenshot_time.to_i
      minutes = seconds / 60
      seconds -= minutes * 60
      hours = minutes / 60
      minutes -= hours * 60

      "#{hours.to_s.rjust(2, '0')}:#{minutes.to_s.rjust(2, '0')}:#{seconds.to_s.rjust(2, '0')}.00"
    end
  end

  def indestructible_reason
    return nil if file_placements_size == 0
    return nil if file_placements_size.nil?
    I18n.t("folio.file.cannot_destroy_file_with_placements")
  end

  def file_list_count
    file_placements_size
  end

  def file_list_source
    if attribution_source.present?
      attribution_source
    elsif attribution_source_url.present?
      begin
        uri = URI.parse(attribution_source_url.gsub("www.", ""))

        if uri.host.present?
          uri.host.split(".", 2)[0]
        end
      rescue StandardError
      end
    end
  end

  def to_label
    file_name.presence || self.class.model_name.human
  end

  def file_modal_additional_fields
    {}
  end

  private
    def set_file_name_for_search
      self.file_name_for_search = self.class.sanitize_filename_for_search(file_name)
    end

    def check_usage_before_destroy
      throw(:abort) if indestructible_reason.present?
      throw(:abort) if file_placements.exists?
    end

    def set_file_track_duration
      if %w[audio video].include?(self.class.human_type)
        self.file_track_duration = Folio::File::GetFileTrackDurationJob.perform_now(file.path, self.class.human_type) # in seconds
        self.preview_track_duration_in_seconds = self.respond_to?(:preview_duration_in_seconds) ? preview_duration_in_seconds : 0
      end
    end

    def set_video_file_dimensions
      if %w[video].include?(self.class.human_type)
        self.file_width, self.file_height = Folio::File::GetVideoDimensionsJob.perform_now(file.path, self.class.human_type)
      end
    end

    def validate_attribution_and_texts_if_needed
      if Rails.application.config.folio_files_require_attribution
        if author_changed? || attribution_source_changed? || attribution_source_url_changed?
          if author.blank? && attribution_source.blank? && attribution_source_url.blank?
            errors.add(:author, :missing_file_attribution)
          end
        end
      end

      if Rails.application.config.folio_files_require_alt
        if self.class.human_type == "image" && alt_changed? && alt.blank?
          errors.add(:alt, :blank)
        end
      end

      if Rails.application.config.folio_files_require_description
        if description_changed? && description.blank?
          errors.add(:description, :blank)
        end
      end
    end
end

# == Schema Information
#
# Table name: folio_files
#
#  id                                :bigint(8)        not null, primary key
#  file_uid                          :string
#  file_name                         :string
#  type                              :string
#  thumbnail_sizes                   :text             default({})
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  file_width                        :integer
#  file_height                       :integer
#  file_size                         :bigint(8)
#  additional_data                   :json
#  file_metadata                     :json
#  hash_id                           :string
#  author                            :string
#  description                       :text
#  file_placements_size              :integer
#  file_name_for_search              :string
#  sensitive_content                 :boolean          default(FALSE)
#  file_mime_type                    :string
#  default_gravity                   :string
#  file_track_duration               :integer
#  aasm_state                        :string
#  remote_services_data              :json
#  preview_track_duration_in_seconds :integer
#  alt                               :string
#  site_id                           :bigint(8)        not null
#  attribution_source                :string
#  attribution_source_url            :string
#  attribution_copyright             :string
#  attribution_licence               :string
#
# Indexes
#
#  index_folio_files_on_by_author                (to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((author)::text, ''::text)))) USING gin
#  index_folio_files_on_by_file_name             (to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((file_name)::text, ''::text)))) USING gin
#  index_folio_files_on_by_file_name_for_search  (to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((file_name_for_search)::text, ''::text)))) USING gin
#  index_folio_files_on_created_at               (created_at)
#  index_folio_files_on_file_name                (file_name)
#  index_folio_files_on_hash_id                  (hash_id)
#  index_folio_files_on_site_id                  (site_id)
#  index_folio_files_on_type                     (type)
#  index_folio_files_on_updated_at               (updated_at)
#
# Foreign Keys
#
#  fk_rails_...  (site_id => folio_sites.id)
#
