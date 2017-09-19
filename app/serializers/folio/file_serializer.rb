# frozen_string_literal: true

module Folio
  class FileSerializer < ActiveModel::Serializer
    attributes :id, :file_size, :file_name

    attribute :size, if: :image?
    attribute :thumb, if: :image?
    attribute :url, if: :image?

    def thumb
      object.thumb('250x250#').url
    end

    def url
      object.file.url
    end

    def file_size
      ActiveSupport::NumberHelper.number_to_human_size(object.file_size)
    end

    def size
      "#{object.file_width} × #{object.file_height}px"
    end

    def image?
      object.type == 'Folio::Image'
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
