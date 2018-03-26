# frozen_string_literal: true

module Folio
  class FileSerializer < ActiveModel::Serializer
    include Engine.routes.url_helpers

    attributes :id, :file_size, :file_name, :type,
               :thumb, :size, :url, :tags,
               :dominant_color, :edit_path

    def thumb
      URI.encode(object.thumb('250x250').url) if image?
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
      object.type == 'Folio::Image'
    end

    def tags
      object.tag_list
    end

    def edit_path
      edit_console_file_path(object)
    end
  end
end

# == Schema Information
#
# Table name: folio_files
#
#  id              :integer          not null, primary key
#  file_uid        :string
#  file_name       :string
#  type            :string
#  thumbnail_sizes :text             default("--- {}\n")
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  file_width      :integer
#  file_height     :integer
#  file_size       :integer
#  mime_type       :string(255)
#  additional_data :json
#
# Indexes
#
#  index_folio_files_on_type  (type)
#
