# frozen_string_literal: true

class Folio::Console::FileSerializer
  include FastJsonapi::ObjectSerializer

  ADMIN_THUMBNAIL_SIZE = "250x250"
  ADMIN_RETINA_THUMBNAIL_SIZE = "500x500"

  attributes :id,
             :file_size,
             :file_name,
             :file_width,
             :file_height,
             :type,
             :thumbnail_sizes,
             :author,
             :description,
             :file_placements_size,
             :sensitive_content,
             :default_gravity,
             :default_gravities_for_select,
             :aasm_state

  attribute :human_type do |object|
    object.class.human_type
  end

  attribute :thumb do |object|
    object.thumb(ADMIN_THUMBNAIL_SIZE).url if object.class.human_type == "image"
  end

  attribute :webp_thumb do |object|
    object.thumb(ADMIN_THUMBNAIL_SIZE).webp_url if object.class.human_type == "image"
  end

  attribute :source_url do |object|
    if object.try(:private?)
      object.file.remote_url(expires: 1.hour.from_now)
    else
      object.file.remote_url
    end
  end

  attribute :url do |object|
    object.file.url if object.class.human_type == "image"
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
    object.aasm.human_state
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
    if object.try(:processing_service) == "jw_player"
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
    else
      object.file_mime_type
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
end
