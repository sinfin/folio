# frozen_string_literal: true

class Folio::Image < Folio::File
  include Folio::DragonflyFormatValidation
  include Folio::Thumbnails
  include Folio::Sitemap::Image

  validate_file_format

  dragonfly_accessor :file do
    after_assign :sanitize_filename
    # after_assign { |file| file.convert! "-auto-orient" }
    after_assign { |file| file.metadata }
  end

  # Get from metadata
  def title
    metadata_compose(["Headline", "Title"])
  end

  def caption
    metadata_compose(["Caption", "Description", "Abstract"])
  end

  def keywords
    metadata_compose(["Keywords"])
  end

  def geo_location
    # Geographic location, e.g.: Limerick, Ireland
    metadata_compose(["LocationName", "SubLocation", "City", "ProvinceState", "CountryName"])
  end

  def self.react_type
    "image"
  end

  private
    def metadata_compose(tags)
      string_arr = tags.collect { |tag| file_metadata.try("[]", tag) }.compact.uniq
      return nil if string_arr.size == 0
      string_arr.join(", ")
    end
end

# == Schema Information
#
# Table name: folio_files
#
#  id                   :bigint(8)        not null, primary key
#  file_uid             :string
#  file_name            :string
#  type                 :string
#  thumbnail_sizes      :text             default({})
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  file_width           :integer
#  file_height          :integer
#  file_size            :bigint(8)
#  mime_type            :string(255)
#  additional_data      :json
#  file_metadata        :json
#  hash_id              :string
#  author               :string
#  description          :text
#  file_placements_size :integer
#  file_name_for_search :string
#  sensitive_content    :boolean          default(FALSE)
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
