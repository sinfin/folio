# frozen_string_literal: true

class Folio::File::Image < Folio::File
  include Folio::Sitemap::Image
  include Folio::ImageMetadataExtraction

  validate_file_format

  dragonfly_accessor :file do
    after_assign :sanitize_filename
    after_assign { |file| file.metadata }
  end

  # IPTC metadata accessors (prefer database fields over metadata compose)
  def title
    headline.presence || metadata_compose(["Headline", "Title"])
  end

  def caption
    description.presence || metadata_compose(["Caption", "Description", "Abstract"])
  end

  def keywords_list
    # Return JSONB array or fallback to legacy metadata
    if keywords.present? && keywords.is_a?(Array)
      keywords
    else
      metadata_compose(["Keywords"])&.split(/[,;]/)&.map(&:strip)&.compact || []
    end
  end

  def geo_location
    # Build location from IPTC fields first, then fallback
    location_parts = [sublocation, city, state_province, country].compact
    if location_parts.any?
      location_parts.join(", ")
    else
      metadata_compose(["LocationName", "SubLocation", "City", "ProvinceState", "CountryName"])
    end
  end

  # Additional IPTC metadata accessors
  def creator_list
    creator.present? && creator.is_a?(Array) ? creator : []
  end

  def keywords_string
    keywords_list.join(", ") if keywords_list.any?
  end

  def copyright_info
    copyright_notice.presence
  end

  def location_coordinates
    return nil unless gps_latitude.present? && gps_longitude.present?
    [gps_latitude, gps_longitude]
  end

  def persons_shown_list
    persons_shown.present? && persons_shown.is_a?(Array) ? persons_shown : []
  end



  def thumbnailable?
    true
  end

  def self.human_type
    "image"
  end

  private
    def metadata_compose(tags)
      string_arr = tags.filter_map { |tag| file_metadata.try("[]", tag) }.uniq
      return nil if string_arr.size == 0
      string_arr.join(", ")
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
