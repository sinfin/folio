# frozen_string_literal: true

class Folio::Document < Folio::File
end

# == Schema Information
#
# Table name: folio_files
#
#  id                   :bigint(8)        not null, primary key
#  file_uid             :string
#  file_name            :string
#  type                 :string
#  thumbnail_sizes      :text             default("--- {}\n")
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  file_width           :integer
#  file_height          :integer
#  file_size            :bigint(8)
#  additional_data      :json
#  file_metadata        :json
#  hash_id              :string
#  author               :string
#  description          :text
#  file_placements_size :integer
#  file_name_for_search :string
#  sensitive_content    :boolean          default(FALSE)
#  file_mime_type       :string
#
# Indexes
#
#  index_folio_files_on_by_author                (to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((author)::text, ''::text)))) USING gin
#  index_folio_files_on_by_file_name_for_search  (to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((file_name_for_search)::text, ''::text)))) USING gin
#  index_folio_files_on_created_at               (created_at)
#  index_folio_files_on_file_name                (file_name)
#  index_folio_files_on_hash_id                  (hash_id)
#  index_folio_files_on_type                     (type)
#  index_folio_files_on_updated_at               (updated_at)
#
