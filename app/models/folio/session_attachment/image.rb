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

# == Schema Information
#
# Table name: folio_session_attachments
#
#  id              :bigint(8)        not null, primary key
#  hash_id         :string
#  file_uid        :string
#  file_name       :string
#  file_size       :bigint(8)
#  file_mime_type  :string
#  type            :string
#  web_session_id  :string
#  placement_type  :string
#  placement_id    :bigint(8)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  file_width      :integer
#  file_height     :integer
#  thumbnail_sizes :json
#
# Indexes
#
#  index_folio_session_attachments_on_hash_id         (hash_id)
#  index_folio_session_attachments_on_placement       (placement_type,placement_id)
#  index_folio_session_attachments_on_type            (type)
#  index_folio_session_attachments_on_web_session_id  (web_session_id)
#
