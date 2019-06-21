# frozen_string_literal: true

class Folio::Console::FileSerializer
  include FastJsonapi::ObjectSerializer

  ADMIN_THUMBNAIL_SIZE = '250x250'

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

  attribute :placements do |object|
    titles = []

    object.file_placements.each do |fp|
      type = fp.placement_title_type.presence || fp.placement_type
      title = fp.placement_title
      next if type.blank? || title.blank?

      klass = type.safe_constantize
      next if klass.blank?

      joined = [klass.model_name.human, title].join(' - ')

      titles << joined unless titles.include?(joined)
    end

    titles
  end

  attribute :extension do |object|
    Mime::Type.lookup(object.mime_type).symbol.to_s.upcase
  end

  attribute :file_name do |object|
    object.file_name.presence ||
    "#{object.class.model_name.human} ##{object.id}"
  end

  link :edit do |object|
    if object.is_a?(Folio::Image)
      "/console/images/#{object.id}/edit"
    else
      "/console/documents/#{object.id}/edit"
    end
  end
end
