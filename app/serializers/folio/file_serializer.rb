# frozen_string_literal: true

module Folio
  class FileSerializer < ActiveModel::Serializer
    include Engine.routes.url_helpers

    # TODO: add :placement once React is ready for it
    attributes :id, :file_size, :file_name, :type,
               :thumb, :size, :url, :tags, :source_image,
               :dominant_color, :edit_path, :extension,
               :placements

    ADMIN_THUMBNAIL_SIZE = '250x250'

    def thumb
      URI.encode(object.thumb(ADMIN_THUMBNAIL_SIZE).url) if image?
    end

    def source_image
      URI.encode(object.file.remote_url) if image?
    end

    def url
      object.file.url if image?
    end

    def size
      "#{object.file_width} × #{object.file_height}px" if image?
    end

    def dominant_color
      if image?
        if object.additional_data
          object.additional_data['dominant_color']
        end
      end
    end

    def image?
      object.is_a?(Image)
    end

    def tags
      object.tags.collect(&:name)
    end

    def edit_path
      if image?
        edit_console_image_path(object)
      else
        edit_console_document_path(object)
      end
    end

    def placements
      titles = []

      object.file_placements.each do |fp|
        type = fp.placement_title_type.presence || fp.placement_type
        title = fp.placement_title
        next if type.blank? || title.blank?

        klass = type.safe_constantize
        next if klass.blank?

        joined = [klass.model_name.human, title].join(' - ')

        titles << joined unless titles.include?(joined)
      end

      titles
    end

    def extension
      Mime::Type.lookup(object.mime_type).symbol.to_s.upcase
    end

    def file_name
      object.file_name.presence ||
      "#{object.class.model_name.human} ##{object.id}"
    end
  end
end

# == Schema Information
#
# Table name: folio_files
#
#  id              :bigint(8)        not null, primary key
#  file_uid        :string
#  file_name       :string
#  type            :string
#  thumbnail_sizes :text             default("--- {}\n")
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  file_width      :integer
#  file_height     :integer
#  file_size       :bigint(8)
#  mime_type       :string(255)
#  additional_data :json
#
# Indexes
#
#  index_folio_files_on_type  (type)
#
