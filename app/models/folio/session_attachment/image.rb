# frozen_string_literal: true

class Folio::SessionAttachment::Image < Folio::SessionAttachment::Base
  include Folio::DragonflyFormatValidation
  include Folio::Thumbnails

  validate_file_format

  def self.human_type
    "image"
  end

  def to_h_thumb
    if admin_thumb.uid
      Folio::S3.url_rewrite(Dragonfly.app.datastore.url_for(admin_thumb.uid, expires: 1.hour.from_now))
    end
  end
end
