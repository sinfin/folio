# frozen_string_literal: true

class Folio::FileSerializer
  include FastJsonapi::ObjectSerializer

  attributes :file_name,
             :file_width,
             :file_height,
             :author

  attribute :human_type do |object|
    object.class.human_type
  end

  attribute :source_url do |object|
    object.file.remote_url
  end
end
