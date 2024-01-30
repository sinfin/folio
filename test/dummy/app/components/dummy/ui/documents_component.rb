# frozen_string_literal: true

class Dummy::Ui::DocumentsComponent < ApplicationComponent
 include ActionView::Helpers::NumberHelper

  def label(placement)
    ext = placement.file.file_extension.presence.try(:upcase)

    if ext.blank?
      if placement.file.file_name.include?(".")
        ext = placement.file.file_name.split(".").last.try(:upcase)
      else
        ext = nil
      end
    end

    size = number_to_human_size(placement.file.file_size)
    "#{placement.to_label} (#{[ext, size].compact.join(', ')})"
  end

  def download_path(*args)
    controller.folio.download_path(*args)
  end
end
