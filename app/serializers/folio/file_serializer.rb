# frozen_string_literal: true

module Folio
  class FileSerializer < ActiveModel::Serializer
    attributes :id, :file_size, :file_name, :type,
               :thumb, :size, :url, :tags,
               :dominant_color, :dark

    def thumb
      object.thumb('250x250#').url if image?
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

    def dark
      if image?
        if object.additional_data
          object.additional_data['dark']
        end
      end
    end

    def image?
      object.type == 'Folio::Image'
    end

    def tags
      object.tag_list
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
#
# Indexes
#
#  index_folio_files_on_type  (type)
#
