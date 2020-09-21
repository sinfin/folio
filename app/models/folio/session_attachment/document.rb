# frozen_string_literal: true

class Folio::SessionAttachment::Document < Folio::SessionAttachment::Base
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
#  thumbnail_sizes :jsonb
#  visit_id        :bigint(8)
#  placement_type  :string
#  placement_id    :bigint(8)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_folio_session_attachments_on_hash_id         (hash_id)
#  index_folio_session_attachments_on_placement       (placement_type,placement_id)
#  index_folio_session_attachments_on_visit_id        (visit_id)
#  index_folio_session_attachments_on_web_session_id  (web_session_id)
#
