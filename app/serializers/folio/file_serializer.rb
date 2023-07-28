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
    if object.try(:private?)
      object.file.remote_url(expires: 1.hour.from_now)
    else
      object.file.remote_url
    end
  end

  attribute :extension do |object|
    Mime::Type.lookup(object.file_mime_type).symbol.to_s.upcase
  end
end
