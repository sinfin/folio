# frozen_string_literal: true

class Folio::Console::SessionAttachments::ListCell < Folio::ConsoleCell
  include ActionView::Helpers::NumberHelper

  def show
    render if model.present?
  end

  def image_for(attachment)
    src = { normal: attachment.to_h_thumb }

    image(src,
          "150x150#",
          contain: true,
          lightbox: {
            "data-lightbox-src" => attachment.to_h_thumb,
            "data-lightbox-width" => attachment.file_width,
            "data-lightbox-height" => attachment.file_height,
          })
  end

  def as_images?
    model.all? { |attachment| attachment.is_a?(Folio::SessionAttachment::Image) }
  end
end
