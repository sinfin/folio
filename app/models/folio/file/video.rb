# frozen_string_literal: true

class Folio::File::Video < Folio::File
  include Folio::File::Video::HasSubtitles

  validate_file_format %w[video/mp4 video/webm]

  def console_show_additional_fields
    additional_fields = {}

    self.class.enabled_subtitle_languages.each do |lang|
      additional_fields[:"subtitles_#{lang}_text"] = { type: :text }
    end

    additional_fields
  end

  def thumbnailable?
    true
  end

  def self.human_type
    "video"
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
#
# Indexes
#
#  index_folio_files_on_by_author                (to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((author)::text, ''::text)))) USING gin
#  index_folio_files_on_by_file_name             (to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((file_name)::text, ''::text)))) USING gin
#  index_folio_files_on_by_file_name_for_search  (to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((file_name_for_search)::text, ''::text)))) USING gin
#  index_folio_files_on_created_at               (created_at)
#  index_folio_files_on_file_name                (file_name)
#  index_folio_files_on_hash_id                  (hash_id)
#  index_folio_files_on_media_source_id          (media_source_id)
#  index_folio_files_on_published_usage_count    (published_usage_count)
#  index_folio_files_on_site_id                  (site_id)
#  index_folio_files_on_type                     (type)
#  index_folio_files_on_updated_at               (updated_at)
#
# Foreign Keys
#
#  fk_rails_...  (media_source_id => folio_media_sources.id)
#  fk_rails_...  (site_id => folio_sites.id)
#
