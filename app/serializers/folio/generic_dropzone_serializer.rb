# frozen_string_literal: true

class Folio::GenericDropzoneSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id,
             :file_size,
             :file_name,
             :file_width,
             :file_height,
             :type

  attribute :source_url do |object|
    Folio::S3.cdn_url_rewrite(object.file.remote_url)
  end

  attribute :url do |object|
    object.file.url if object.is_a?(Folio::File::Image)
  end

  attribute :title do |object|
    object.try(:title)
  end
end
