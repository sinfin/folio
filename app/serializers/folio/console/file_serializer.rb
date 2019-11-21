# frozen_string_literal: true

class Folio::Console::FileSerializer
  include FastJsonapi::ObjectSerializer

  ADMIN_THUMBNAIL_SIZE = '250x250'
  ADMIN_RETINA_THUMBNAIL_SIZE = '500x500'

  attributes :id,
             :file_size,
             :file_name,
             :type

  attribute :thumb do |object|
    object.thumb(ADMIN_THUMBNAIL_SIZE).url if object.is_a?(Folio::Image)
  end

  attribute :source_image do |object|
    object.file.remote_url if object.is_a?(Folio::Image)
  end

  attribute :url do |object|
    object.file.url if object.is_a?(Folio::Image)
  end

  attribute :dominant_color do |object|
    if object.is_a?(Folio::Image)
      if object.additional_data
        object.additional_data['dominant_color']
      end
    end
  end

  attribute :tags do |object|
    object.tags.collect(&:name).sort
  end

  attribute :extension do |object|
    Mime::Type.lookup(object.mime_type).symbol.to_s.upcase
  end

  attribute :file_name do |object|
    object.file_name.presence ||
    "#{object.class.model_name.human} ##{object.id}"
  end

  link :edit do |object|
    if object.persisted?
      Folio::Engine.routes
                   .url_helpers
                   .url_for([:edit, :console, object, only_path: true])
    end
  end
end
