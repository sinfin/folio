# frozen_string_literal: true

class Folio::File::Image < Folio::File
  include Folio::Sitemap::Image
  include Folio::MetadataExtraction

  validate_file_format(%w[jpeg png bmp gif svg tiff webp avif heic heif])

  dragonfly_accessor :file do
    after_assign :sanitize_filename
    after_assign { |file| file.metadata }
  end

  # IPTC metadata accessors (prefer database fields over metadata compose)
  def title
    headline.presence || headline_from_metadata.presence || metadata_compose(["Headline", "Title"])
  end

  def caption
    description.presence || metadata_compose(["Caption", "Description", "Abstract"])
  end

  def keywords_list
    # Use JSON getter from concern
    keywords_from_metadata
  end

  def geo_location
    # Use JSON getters from concern
    location_parts = [sublocation, city, state_province, country].compact
    if location_parts.any?
      location_parts.join(", ")
    else
      metadata_compose(["LocationName", "SubLocation", "City", "ProvinceState", "CountryName"])
    end
  end

  # Additional IPTC metadata accessors
  def creator_list
    # Use JSON getter from concern
    creator
  end

  def keywords_string
    keywords_list.join(", ") if keywords_list.any?
  end

  def copyright_info
    # Use JSON getter from concern
    copyright_notice
  end

  def location_coordinates
    return nil unless gps_latitude.present? && gps_longitude.present?
    [gps_latitude, gps_longitude]
  end

  def persons_shown_list
    # Use JSON getter from concern
    persons_shown_from_metadata
  end


  def thumbnailable?
    true
  end

  def self.human_type
    "image"
  end

  # Override after_process hook to extract metadata synchronously during upload
  def after_process
    super

    # Extract metadata synchronously during file processing
    # (can't use should_extract_metadata? here as file is now available)
    extract_image_metadata_during_processing if should_extract_metadata_during_processing?
  end

  # Make metadata_compose public for file_placement access
  def metadata_compose(tags)
    string_arr = tags.filter_map { |tag| file_metadata.try("[]", tag) }.uniq
    return nil if string_arr.size == 0
    string_arr.join(", ")
  end

  private
    def should_extract_metadata_during_processing?
      return false unless Rails.application.config.folio_image_metadata_extraction_enabled
      return false unless file.present? && (file.respond_to?(:path) || file.is_a?(String))

      # Skip extraction in test mode when explicitly disabled
      return false if Rails.env.test? && ENV["FOLIO_SKIP_METADATA_EXTRACTION"] == "true"

      # Check if we have new IPTC fields (backward compatibility)
      return false unless has_iptc_metadata_fields?

      # Check if metadata already extracted (avoid re-extraction)
      return false if file_metadata_extracted_at.present?

      # Check if exiftool is available
      system("which exiftool > /dev/null 2>&1")
    end

    def extract_image_metadata_during_processing
      # For S3/remote files, we need to download temporarily to extract metadata
      # This works during upload when file is still being processed
      file_path = get_file_path_for_extraction
      return unless file_path && File.exist?(file_path)

      Rails.logger.info "Extracting metadata for #{file_name} during processing..."

      require "open3"

      base_options = Rails.application.config.folio_image_metadata_exiftool_options || ["-G1", "-struct", "-n"]

      # Always use UTF-8 charset for IPTC (our mojibake fix)
      charset_options = ["-charset", "iptc=utf8"]
      command = ["exiftool", "-j", *base_options, *charset_options, file_path]

      Rails.logger.debug "ExifTool command: #{command.join(' ')}"

      stdout, stderr, status = Open3.capture3(*command)

      if status.success?
        raw_metadata = JSON.parse(stdout).first
        if raw_metadata.present?
          map_iptc_metadata(raw_metadata)
          Rails.logger.info "Successfully extracted metadata for #{file_name} with UTF-8 charset"
        else
          Rails.logger.warn "No metadata found for #{file_name}"
        end
      else
        Rails.logger.warn "ExifTool error for #{file_name}: #{stderr}"
      end

    rescue => e
      Rails.logger.error "Failed to extract metadata during processing for #{file_name}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end

    def get_file_path_for_extraction
      # During processing, the file should still be available locally via Dragonfly
      if file.respond_to?(:path) && file.path
        file.path
      elsif file.respond_to?(:url) && file.url
        # For remote files, try to get temp file path from Dragonfly
        begin
          file.temp_object.path if file.respond_to?(:temp_object) && file.temp_object
        rescue
          nil
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
