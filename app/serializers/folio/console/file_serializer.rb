# frozen_string_literal: true

class Folio::Console::FileSerializer
  include FastJsonapi::ObjectSerializer

  ADMIN_THUMBNAIL_SIZE = "250x250"
  ADMIN_RETINA_THUMBNAIL_SIZE = "500x500"

  attributes :id,
             :file_size,
             :file_name,
             :file_mime_type,
             :file_width,
             :file_height,
             :type,
             :created_at,
             :thumbnail_sizes,
             :author,
             :attribution_source,
             :attribution_source_url,
             :attribution_copyright,
             :attribution_licence,
             :description,
             :file_placements_size,
             :sensitive_content,
             :default_gravity,
             :default_gravities_for_select,
             :aasm_state,
             :alt,
             # Essential metadata fields (database columns)
             :headline,
             :capture_date,
             :gps_latitude,
             :gps_longitude,
             :file_metadata_extracted_at

  # Dynamic metadata from JSON (for frontend consumption)
  attribute :dynamic_metadata do |object|
    object.respond_to?(:file_metadata) ? object.file_metadata || {} : {}
  end

  # Image-specific metadata accessors (only for Image files)
  attribute :creator_list do |object|
    object.respond_to?(:creator_list) ? object.creator_list : []
  end

  attribute :keywords_list do |object|
    object.respond_to?(:keywords_list) ? object.keywords_list : []
  end

  attribute :copyright_info do |object|
    object.respond_to?(:copyright_info) ? object.copyright_info : nil
  end

  attribute :persons_shown_list do |object|
    object.respond_to?(:persons_shown_list) ? object.persons_shown_list : []
  end

  attribute :location_coordinates do |object|
    object.respond_to?(:location_coordinates) ? object.location_coordinates : nil
  end

  attribute :geo_location do |object|
    object.respond_to?(:geo_location) ? object.geo_location : nil
  end

  attribute :human_type do |object|
    object.class.human_type
  end

  attribute :thumb do |object|
    object.thumb(ADMIN_THUMBNAIL_SIZE).url if object.class.human_type == "image" && !object.try(:private?)
  end

  attribute :webp_thumb do |object|
    object.thumb(ADMIN_THUMBNAIL_SIZE).webp_url if object.class.human_type == "image" && !object.try(:private?)
  end

  attribute :source_url do |object|
    unless object.try(:private?)
      Folio::S3.cdn_url_rewrite(object.file.remote_url)
    end
  end

  attribute :url do |object|
    object.file.url if object.class.human_type == "image" && !object.try(:private?)
  end

  attribute :dominant_color do |object|
    if object.class.human_type == "image"
      if object.additional_data
        object.additional_data["dominant_color"]
      end
    end
  end

  attribute :tags do |object|
    object.tags.collect(&:name).sort
  end

  attribute :extension do |object|
    Mime::Type.lookup(object.file_mime_type).symbol.to_s.upcase
  end

  attribute :file_name do |object|
    object.file_name.presence ||
    "#{object.class.model_name.human} ##{object.id}"
  end

  attribute :default_gravities_for_select do |object|
    object.class.default_gravities_for_select
  end

  attribute :aasm_state_human do |object|
    if object.processing? && object.remote_services_data.try(:[], "progress_percentage")
      "#{object.aasm.human_state} (#{object.remote_services_data.try(:[], "progress_percentage")}%)"
    else
      object.aasm.human_state
    end
  end

  attribute :aasm_state_color do |object|
    if object.aasm_state
      state_object = Folio::File.last.aasm.state_object_for_name(object.aasm_state.to_sym)
      if state_object && state_object.options
        state_object.options[:color]
      end
    end
  end

  attribute :jw_player_api_url do |object|
    if object.try(:processing_service) == "jw_player" && object.ready?
      if object.remote_key
        Folio::Engine.routes
                     .url_helpers
                     .video_url_console_api_jw_player_path(file_id: object.id)
      end
    end
  end

  attribute :player_source_mime_type do |object|
    if object.try(:processing_service) == "mux" && object.ready?
      "application/x-mpegurl"
    elsif object.file_mime_type
      if object.file_mime_type.match?(%r{audio/.+-aac-.+})
        "audio/aac"
      else
        object.file_mime_type
      end
    end
  end

  attribute :mux_source_url do |object|
    if object.try(:processing_service) == "mux" && object.ready?
      object.remote_signed_full_url
    end
  end

  attribute :preview_duration do |object|
    object.try(:preview_duration)
  end

  attribute :additional_html_api_url do |object|
    Rails.application.config.folio_console_files_additional_html_api_url_lambda.call(object)
  end

  attribute :subtitles_html_api_url do |object|
    if object.is_a?(Folio::File::Video) && object.try(:subtitles_enabled?)
      Folio::Engine.routes
                   .url_helpers
                   .subtitles_html_console_api_file_video_path(object)
    end
  end

  attribute :file_modal_additional_fields do |object|
    object.file_modal_additional_fields.map do |name, hash|
      h = {
        name:,
        type: hash[:type],
        label: hash[:label] || object.class.human_attribute_name(name),
        value: object.send(name),
      }

      if hash[:collection]
        if hash[:include_blank] != false
          h[:collection] = [["", ""]]
        else
          h[:value] ||= hash[:collection][0][1]
          h[:collection] = []
        end

        h[:collection] += hash[:collection]
      end

      h
    end
  end

  attribute :imported_from_photo_archive do |object|
    if Rails.application.config.folio_photo_archive_enabled
      if object.respond_to?(:imported_from_photo_archive?)
        object.imported_from_photo_archive?
      end
    end
  end

  # Legacy metadata attributes removed - use dynamic_metadata or image-specific accessors instead

  # Technical EXIF data and additional metadata is now available via dynamic_metadata JSON attribute
end
