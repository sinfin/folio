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
             :default_gravities_for_select

  attribute :react_type do |object|
    object.class.react_type
  end

  attribute :thumb do |object|
    object.thumb(ADMIN_THUMBNAIL_SIZE).url if object.class.react_type == "image"
  end

  attribute :webp_thumb do |object|
    object.thumb(ADMIN_THUMBNAIL_SIZE).webp_url if object.class.react_type == "image"
  end

  attribute :source_url do |object|
    object.file.remote_url
  end

  attribute :url do |object|
    object.file.url if object.class.react_type == "image"
  end

  attribute :dominant_color do |object|
    if object.class.react_type == "image"
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
end
