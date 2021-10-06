# frozen_string_literal: true

class Folio::SessionAttachment::Image < Folio::SessionAttachment::Base
  include Folio::DragonflyFormatValidation

  # respect app/models/folio/session_attachment/base.rb when changing!
  dragonfly_accessor :file do
    after_assign :sanitize_filename
    # after_assign { |file| file.convert! "-auto-orient" }

    storage_options do |attachment|
      {
        headers: { "x-amz-acl" => "private" },
        path: "session_attachments/#{hash_id}/#{sanitize_filename}",
      }
    end
  end

  ALLOWED_FORMATS = %w[jpeg png bmp gif svg tiff]

  validate_file_format ALLOWED_FORMATS
  def to_h_thumb
    file.remote_url(expires: 1.hour.from_now)
  end
end

# == Schema Information
#
# Table name: folio_session_attachments
#
#  id             :bigint(8)        not null, primary key
#  hash_id        :string
#  file_uid       :string
#  file_name      :string
#  file_size      :bigint(8)
#  file_mime_type :string
#  type           :string
#  web_session_id :string
#  placement_type :string
#  placement_id   :bigint(8)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  file_width     :integer
#  file_height    :integer
#
# Indexes
#
#  index_folio_session_attachments_on_hash_id         (hash_id)
#  index_folio_session_attachments_on_placement       (placement_type,placement_id)
#  index_folio_session_attachments_on_type            (type)
#  index_folio_session_attachments_on_web_session_id  (web_session_id)
#
