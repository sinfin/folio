# frozen_string_literal: true

class Folio::Files::SetAdditionalDataJob < Folio::ApplicationJob
  queue_as :slow

  def perform(file_model)
    additional_data = file_model.additional_data || {}

    image = Vips::Image.new_from_file(file_model.file.path)

    if file_model.gif?
      begin
        gif_image = Vips::Image.new_from_file(file_model.file.path, page: 1)
        gif_image = nil
        additional_data[:animated] = true
      rescue Vips::Error
        additional_data[:animated] = false
      end
    end


    rgb = [
      image.stats.getpoint(4, 1)[0],
      image.stats.getpoint(4, 2)[0],
      image.stats.getpoint(4, 3)[0],
    ]

    additional_data[:dominant_color] = "#%02X%02X%02X" % rgb
    additional_data[:dark] = rgb.sum < 3 * 255 / 2.0

    file_model.update!(additional_data: additional_data)
  end
end
