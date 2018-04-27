# frozen_string_literal: true

class Folio::Console::SingleImageSelectCell < FolioCell
  def f
    model
  end

  def file_attr
    options[:attr_name]
  end

  def remove_file_attr
    "remove_#{options[:attr_name]}".to_sym
  end

  def image
    f.object.send(file_attr)
  end

  def image_src
    image.thumb(Folio::FileSerializer::ADMIN_THUMBNAIL_SIZE).url
  end

  def wrap_class
    image.present? ? 'folio-console-has-image' : nil
  end
end
