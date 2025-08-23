# frozen_string_literal: true

module Folio::ImageMetadataExtraction
  extend ActiveSupport::Concern

  included do
    # Use async job by default, fallback to synchronous for tests or when jobs are disabled
    after_commit :extract_image_metadata_async, on: :create, if: :should_extract_metadata?
  end

  def should_extract_metadata?
    return false unless Rails.application.config.folio_image_metadata_extraction_enabled
    return false unless is_a?(Folio::File::Image)
    return false unless file.present? && (file.respond_to?(:path) || file.is_a?(String))
    
    # Don't extract during data migrations to avoid interfering with legacy migration
    return false if Rails.env.test? && ENV['FOLIO_MIGRATION_MODE'] == 'true'
    
    # Check if we have new IPTC fields (backward compatibility)
    return false unless has_iptc_metadata_fields?
    
    # Check if exiftool is available
    system("which exiftool > /dev/null 2>&1")
  end

  def extract_image_metadata_async
    if defined?(ActiveJob) && Rails.application.config.active_job.queue_adapter != :test
      Folio::ExtractMetadataJob.perform_later(self)
    else
      # Synchronous extraction for tests or when jobs are disabled
      extract_image_metadata_sync
    end
  end

  def extract_image_metadata_sync
    return unless should_extract_metadata?
    
    metadata = extract_raw_metadata_with_exiftool
    return unless metadata.present?
    
    map_iptc_metadata(metadata)
    save if changed?
  rescue => e
    Rails.logger.error "Failed to extract metadata for #{file_name}: #{e.message}"
  end

  # Manual metadata extraction (for existing images)
  def extract_metadata!(force: false)
    if defined?(ActiveJob) && Rails.application.config.active_job.queue_adapter != :test
      Folio::ExtractMetadataJob.perform_later(self, force: force)
    else
      extract_image_metadata_sync
    end
  end

  def map_iptc_metadata(raw_metadata)
    return unless raw_metadata.present?
    
    # Use the dedicated service for mapping
    mapped_fields = Folio::Metadata::IptcFieldMapper.map_metadata(raw_metadata)
    skip_fields = Rails.application.config.folio_image_metadata_skip_fields || []
    
    mapped_fields.each do |field_name, value|
      next if skip_fields.include?(field_name)
      next if self[field_name].present? # Preserve existing data (blank field protection)
      next unless value.present?
      
      self[field_name] = value
    end
  end

  private

  def extract_raw_metadata_with_exiftool
    return unless file.present? && File.exist?(file.path)
    
    require 'open3'
    
    options = Rails.application.config.folio_image_metadata_exiftool_options || ["-G1", "-struct", "-n"]
    command = ["exiftool", "-j", *options, file.path]
    
    stdout, stderr, status = Open3.capture3(*command)
    
    if status.success?
      JSON.parse(stdout).first
    else
      Rails.logger.warn "ExifTool error for #{file_name}: #{stderr}"
      nil
    end
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse ExifTool output for #{file_name}: #{e.message}"
    nil
  end
end
