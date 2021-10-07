# frozen_string_literal: true

class Folio::Console::SessionAttachments::ListCell < Folio::ConsoleCell
  include ActionView::Helpers::NumberHelper

  def show
    render if model.present?
  end

  def image_for(attachment)
    admin_image(attachment, lightbox: true)
  end

  def as_images?
    model.all? { |attachment| attachment.is_a?(Folio::SessionAttachment::Image) }
  end
end
