# frozen_string_literal: true

class Folio::File::Image < Folio::File
  include Folio::Sitemap::Image

  validate_file_format(%w[jpeg png bmp gif svg tiff webp avif heic heif])

  # Metadata extraction after image creation
  after_commit :extract_metadata_async, on: :create, if: :should_extract_metadata?

  dragonfly_accessor :file do
    after_assign :sanitize_filename
    after_assign { |file| file.metadata }
  end

  # Legacy metadata accessors (simplified for backward compatibility)
  def title
    headline.presence || file_metadata&.dig("headline")
  end

  def caption
    description.presence || file_metadata&.dig("caption")
  end

  def keywords_list
    file_metadata&.dig("keywords") || []
  end

  def geo_location
    # Build from file_metadata JSON
    location_parts = [
      file_metadata&.dig("sublocation"),
      file_metadata&.dig("city"),
      file_metadata&.dig("state_province"),
      file_metadata&.dig("country")
    ].compact

    location_parts.join(", ") if location_parts.any?
  end

  def creator_list
    file_metadata&.dig("creator") || []
  end

  def keywords_string
    keywords_list.join(", ") if keywords_list.any?
  end

  def copyright_info
    file_metadata&.dig("copyright_notice")
  end

  def location_coordinates
    return nil unless gps_latitude.present? && gps_longitude.present?
    [gps_latitude, gps_longitude]
  end

  def persons_shown_list
    file_metadata&.dig("persons_shown") || []
  end


  def thumbnailable?
    true
  end

  def self.human_type
    "image"
  end

  # Manual metadata extraction (for existing images)
  def extract_metadata!(force: false, user_id: nil)
    Folio::Metadata::ExtractionService.new(self).extract!(force: force, user_id: user_id)
  end

  # Metadata extraction callbacks (delegate to service)
  def should_extract_metadata?
    Folio::Metadata::ExtractionService.should_extract?(self)
  end

  def extract_metadata_async
    Folio::Metadata::ExtractionService.extract_async(self)
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
#  headline                          :string
#  capture_date                      :datetime
#  gps_latitude                      :decimal(10, 6)
#  gps_longitude                     :decimal(10, 6)
#  file_metadata_extracted_at        :datetime
#
# Indexes
#
#  index_folio_files_on_by_author                       (to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((author)::text, ''::text)))) USING gin
#  index_folio_files_on_by_file_name                    (to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((file_name)::text, ''::text)))) USING gin
#  index_folio_files_on_by_file_name_for_search         (to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((file_name_for_search)::text, ''::text)))) USING gin
#  index_folio_files_on_capture_date                    (capture_date)
#  index_folio_files_on_created_at                      (created_at)
#  index_folio_files_on_file_metadata_extracted_at      (file_metadata_extracted_at)
#  index_folio_files_on_file_name                       (file_name)
#  index_folio_files_on_gps_latitude_and_gps_longitude  (gps_latitude,gps_longitude)
#  index_folio_files_on_hash_id                         (hash_id)
#  index_folio_files_on_headline                        (headline)
#  index_folio_files_on_site_id                         (site_id)
#  index_folio_files_on_type                            (type)
#  index_folio_files_on_updated_at                      (updated_at)
#
# Foreign Keys
#
#  fk_rails_...  (site_id => folio_sites.id)
#
