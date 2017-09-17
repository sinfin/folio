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
