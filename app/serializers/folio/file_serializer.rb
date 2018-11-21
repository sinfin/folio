# frozen_string_literal: true

module Folio
  class FileSerializer < ActiveModel::Serializer
    include Engine.routes.url_helpers
    include ActionView::Helpers::NumberHelper

    # TODO: add :placement once React is ready for it
    attributes :id, :file_size, :file_name, :type,
               :thumb, :size, :url, :tags,
               :dominant_color, :edit_path, :extension

    ADMIN_THUMBNAIL_SIZE = '250x250'

    def thumb
      URI.encode(object.thumb(ADMIN_THUMBNAIL_SIZE).url) if image?
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
      keys = %i[file_placements]
      keys << :cover_placements if image?

      keys.each do |key|
        object.send(key).each do |fp|
          title = fp.placement.try(:title) || fp.placement.try(:name)
          next if title.blank?

          model_name = fp.placement.class.model_name.human
          joined = [model_name, title].join(' - ')

          titles << joined unless titles.include?(joined)
        end
      end

      titles
    end

    def extension
      Mime::Type.lookup(object.file.mime_type).symbol.to_s.upcase
    end

    def file_size
      number_to_human_size(object.file_size)
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
