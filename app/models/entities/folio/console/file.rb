# frozen_string_literal: true

class Entities::Folio::Console::File < Grape::Entity
  expose :id,
         :file_size,
         :file_name,
         :type,
         :thumb,
         :url,
         :tags,
         :source_image,
         :dominant_color,
         :edit_path,
         :extension,
         :placements

  def thumb
    if @object.is_a?(Folio::Image)
      @object.thumb(Folio::Image::ADMIN_THUMBNAIL_SIZE).url
    end
  end

  def url
    if @object.is_a?(Folio::Image)
      @object.file.remote_url
    end
  end

  def source_image
    if @object.is_a?(Folio::Image)
      @object.file.remote_url
    end
  end

  def dominant_color
    if @object.additional_data
      @object.additional_data['dominant_color']
    end
  end

  def edit_path
    url_for([:console, :edit, @object])
  end
end
