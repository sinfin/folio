# frozen_string_literal: true

class Folio::Console::SingleFileSelectCell < Folio::ConsoleCell
  include ActionView::Helpers::NumberHelper

  def f
    model
  end

  def file_attr
    options[:attr_name]
  end

  def remove_file_attr
    options[:remove_file_attr].presence || "remove_#{file_attr}"
  end

  def file
    f.object.send(file_attr)
  end

  def file_src
    file.thumb(Folio::FileSerializer::ADMIN_THUMBNAIL_SIZE).url
  end

  def wrap_class
    'folio-console-single-file-select--has-file' if filled?
  end

  def file_class
    'form-control folio-console-single-file-select-file'
  end

  def destroy_class
    'folio-console-single-file-select__destroy'
  end

  def filled?
    f.object.present? && f.object.file.present?
  end
end
