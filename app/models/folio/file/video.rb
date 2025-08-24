# frozen_string_literal: true

class Folio::File::Video < Folio::File
  include Folio::File::Video::HasSubtitles

  validate_file_format %w[video/mp4 video/webm]

  def file_modal_additional_fields
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
#  author_legacy                     :string
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
#  alt_legacy                        :string
#  site_id                           :bigint(8)        not null
#  attribution_source                :string
#  attribution_source_url            :string
#  attribution_copyright             :string
#  attribution_licence               :string
#  headline                          :string
#  creator                           :jsonb
#  caption_writer                    :string
#  credit_line                       :string
#  source                            :string
#  copyright_notice                  :text
#  copyright_marked                  :boolean          default(FALSE)
#  usage_terms                       :text
#  rights_usage_info                 :string
#  keywords                          :jsonb
#  intellectual_genre                :string
#  subject_codes                     :jsonb
#  scene_codes                       :jsonb
#  event                             :string
#  category                          :string
#  urgency                           :integer
#  persons_shown                     :jsonb
#  persons_shown_details             :jsonb
#  organizations_shown               :jsonb
#  location_created                  :jsonb
#  location_shown                    :jsonb
#  sublocation                       :string
#  city                              :string
#  state_province                    :string
#  country                           :string
#  country_code                      :string(2)
#  camera_make                       :string
#  camera_model                      :string
#  lens_info                         :string
#  capture_date                      :datetime
#  capture_date_offset               :string
#  gps_latitude                      :decimal(10, 6)
#  gps_longitude                     :decimal(10, 6)
#  orientation                       :integer
#  alt                               :string
#  author                            :string
#  file_metadata_extracted_at        :datetime
#
# Indexes
#
#  index_folio_files_on_by_author                       (to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((author_legacy)::text, ''::text)))) USING gin
#  index_folio_files_on_by_file_name                    (to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((file_name)::text, ''::text)))) USING gin
#  index_folio_files_on_by_file_name_for_search         (to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((file_name_for_search)::text, ''::text)))) USING gin
#  index_folio_files_on_capture_date                    (capture_date)
#  index_folio_files_on_country_code                    (country_code)
#  index_folio_files_on_created_at                      (created_at)
#  index_folio_files_on_creator                         (creator) USING gin
#  index_folio_files_on_file_metadata_extracted_at      (file_metadata_extracted_at)
#  index_folio_files_on_file_name                       (file_name)
#  index_folio_files_on_gps_latitude_and_gps_longitude  (gps_latitude,gps_longitude)
#  index_folio_files_on_hash_id                         (hash_id)
#  index_folio_files_on_keywords                        (keywords) USING gin
#  index_folio_files_on_persons_shown                   (persons_shown) USING gin
#  index_folio_files_on_site_id                         (site_id)
#  index_folio_files_on_source                          (source)
#  index_folio_files_on_subject_codes                   (subject_codes) USING gin
#  index_folio_files_on_type                            (type)
#  index_folio_files_on_updated_at                      (updated_at)
#
# Foreign Keys
#
#  fk_rails_...  (site_id => folio_sites.id)
#
