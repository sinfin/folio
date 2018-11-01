# frozen_string_literal: true

class Folio::Console::SingleFileSelectCell < FolioCell
  def f
    model
  end

  def file_attr
    options[:attr_name]
  end

  def remove_file_attr
    options[:remove_file_attr].presence || '_destroy'
  end

  def file
    f.object.send(file_attr)
  end

  def file_src
    file.thumb(Folio::FileSerializer::ADMIN_THUMBNAIL_SIZE).url
  end

  def wrap_class
    [
      file.present? ? 'folio-console-has-file' : nil,
      "folio-console-single-file-select-as-#{options[:as]}"
    ].compact.join(' ')
  end

  def file_class
    'form-control folio-console-single-file-select-file'
  end

  def destroy_class
    'folio-console-single-file-select-destroy'
  end
end
