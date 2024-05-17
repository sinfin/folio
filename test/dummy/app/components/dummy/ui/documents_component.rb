# frozen_string_literal: true

class Dummy::Ui::DocumentsComponent < ApplicationComponent
  def initialize(document_placements:, title: nil)
    @document_placements = document_placements
    @title = title
  end

  def render?
    @document_placements.present? || @title.present?
  end

  include ActionView::Helpers::NumberHelper

  def label(placement)
    ext = placement.file.file_extension.presence.try(:upcase)

    if ext.blank?
      ext = if placement.file.file_name.include?(".")
        placement.file.file_name.split(".").last.try(:upcase)
      end
    end

    size = number_to_human_size(placement.file.file_size)
    "#{placement.to_label} (#{[ext, size].compact.join(', ')})"
  end

  def download_path(*)
    controller.folio.download_path(*)
  end

  def href(placement)
    download_path(placement.file, placement.file.file_name)
  end
end
