module Folio
  class FileSerializer < ActiveModel::Serializer
    attributes :id, :file_size, :thumb_url
    attribute :size, if: :image?

    def thumb_url
      object.thumb('250x250#').url
    end

    def file_size
      ActiveSupport::NumberHelper.number_to_human_size(object.file_size)
    end

    def size
      "#{object.file_width} × #{object.file_height}px"
    end

    def image?
      object.class == Folio::Image
    end
  end
end
