# frozen_string_literal: true

class Folio::File::Audio < Folio::File
  include Folio::S3::Client

  ACCEPTED_FILE_FORMATS = %w[
    audio/mpeg
    audio/mp3
    audio/aac
    audio/x-hx-aac-adts
    audio/mp4
    audio/x-m4a
    audio/wav
    audio/x-wav
    audio/vnd.wave
    audio/flac
    audio/x-flac
    audio/ogg
    application/ogg
  ].freeze

  validate_file_format ACCEPTED_FILE_FORMATS

  def mapped_metadata
    metadata = file_metadata.to_h

    {
      title: metadata["title"],
      artist: metadata["artist"],
      album: metadata["album"],
      track: metadata["track"],
      codec_name: metadata["codec_name"],
      bitrate_kbps: metadata["bitrate_kbps"],
      sample_rate_hz: metadata["sample_rate_hz"],
      channels: metadata["channels"],
      duration_seconds: metadata["duration_seconds"],
      artwork_present: metadata["artwork_present"],
    }.compact
  end

  def artwork_image
    @artwork_image ||= begin
      image_id = remote_services_data.to_h["artwork_image_id"]
      return if image_id.blank?

      Folio::File::Image.find_by(id: image_id)
    end
  end

  def artwork_image_placement
    return unless artwork_image.present?

    Folio::FilePlacement::Cover.new(file: artwork_image)
  end

  def playable_storage_data
    remote_services_data.to_h["playable"].to_h
  end

  def playable_file_path
    playable_storage_data["path"]
  end

  def playable_content_type
    playable_storage_data["content_type"].presence || file_mime_type
  end

  def playable_extension
    playable_storage_data["extension"].presence || file_extension.to_s
  end

  def playable_download_url(expires_in: 15.minutes.to_i)
    return unless playable_file_path.present?

    test_aware_presign_url(s3_path: playable_file_path,
                           method_name: :get_object)
  end

  def low_quality_source?
    remote_services_data.to_h["quality_warning"] == "low_bitrate"
  end

  def private?
    true
  end

  def self.human_type
    "audio"
  end

  def extract_metadata!(force: false, save: true)
    Folio::File::AudioProcessingService.new(self).extract_metadata!(force:, save:)
  end

  def should_extract_metadata?
    return false unless file.present?
    return false if file_metadata_extracted_at.present? && !attached_file_changed?

    true
  end

  def process_attached_file
    Folio::File::ProcessAudioJob.perform_later(self)
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
#  slug                              :string
#  author                            :string
#  description                       :text
#  file_placements_count             :integer          default(0), not null
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
#  headline                          :string
#  capture_date                      :datetime
#  gps_latitude                      :decimal(10, 6)
#  gps_longitude                     :decimal(10, 6)
#  file_metadata_extracted_at        :datetime
#  media_source_id                   :bigint(8)
#  attribution_max_usage_count       :integer
#  published_usage_count             :integer          default(0), not null
#  thumbnail_configuration           :jsonb
#  created_by_folio_user_id          :bigint(8)
#
# Indexes
#
#  index_folio_files_on_by_author                 (to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((author)::text, ''::text)))) USING gin
#  index_folio_files_on_by_file_name              (to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((file_name)::text, ''::text)))) USING gin
#  index_folio_files_on_by_file_name_for_search   (to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((file_name_for_search)::text, ''::text)))) USING gin
#  index_folio_files_on_by_label_query            ((((to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((file_name_for_search)::text, ''::text))) || to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((headline)::text, ''::text)))) || to_tsvector('simple'::regconfig, folio_unaccent(COALESCE(description, ''::text)))))) USING gin
#  index_folio_files_on_created_at                (created_at)
#  index_folio_files_on_created_by_folio_user_id  (created_by_folio_user_id)
#  index_folio_files_on_file_name                 (file_name)
#  index_folio_files_on_media_source_id           (media_source_id)
#  index_folio_files_on_published_usage_count     (published_usage_count)
#  index_folio_files_on_site_id                   (site_id)
#  index_folio_files_on_slug                      (slug)
#  index_folio_files_on_type                      (type)
#  index_folio_files_on_updated_at                (updated_at)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_folio_user_id => folio_users.id) ON DELETE => nullify
#  fk_rails_...  (media_source_id => folio_media_sources.id)
#  fk_rails_...  (site_id => folio_sites.id)
#
