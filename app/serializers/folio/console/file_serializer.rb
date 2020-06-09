# frozen_string_literal: true

class Folio::Console::FileSerializer
  include FastJsonapi::ObjectSerializer

  ADMIN_THUMBNAIL_SIZE = '250x250'
  ADMIN_RETINA_THUMBNAIL_SIZE = '500x500'

  attributes :id,
             :file_size,
             :file_name,
             :file_width,
             :file_height,
             :type,
             :thumbnail_sizes

  attribute :thumb do |object|
    object.thumb(ADMIN_THUMBNAIL_SIZE).url if object.is_a?(Folio::Image)
  end

  attribute :source_url do |object|
    object.file.remote_url
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

  attribute :file_placements_count do |object|
    object.file_placements.size
  end

  attribute :some_file_placements do |object|
    ary = []

    object.file_placements.first(10).each do |file_placement|
      label = label_for_placement(file_placement)
      url = url_for_placement(file_placement)
      if label && url
        ary << { label: label, url: url, id: file_placement.id }
      end
    end

    ary
  end

  link :edit do |object|
    if object.persisted?
      Folio::Engine.routes
                   .url_helpers
                   .url_for([:edit, :console, object, only_path: true])
    end
  end

  private
    def self.url_for_placement(file_placement)
      placement = file_placement.placement

      if placement.is_a?(Folio::Atom::Base)
        placement = placement.placement
      end

      Folio::Engine.app.url_helpers.url_for([:edit, :console, placement, only_path: true])
    rescue StandardError
      Folio::Engine.app.url_helpers.url_for([:console, placement, only_path: true])
    rescue StandardError
      nil
    end

    def self.label_for_placement(file_placement)
      placement = file_placement.placement

      if placement.is_a?(Folio::Atom::Base)
        placement = placement.placement
      end

      "#{placement.class.model_name.human}: #{placement.to_label}"
    rescue StandardError
      nil
    end
end
