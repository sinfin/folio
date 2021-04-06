# frozen_string_literal: true

class Folio::SetFileAdditionalDataJob < Folio::ApplicationJob
  queue_as :slow

  def perform(file)
    additional_data = file.additional_data || {}

    if file.gif?
      identify = MiniMagick::Tool::Identify.new do |i|
        i << file.file.path
      end
      animated = identify.split("\n").size > 1
      additional_data[:animated] = animated
    end

    dominant_color = MiniMagick::Tool::Convert.new do |convert|
      convert.merge! [
        file.file.path,
        "+dither",
        "-colors", "1",
        "-unique-colors",
        "txt:"
      ]
    end

    if dominant_color.present?
      hex = dominant_color[/#\S+/]
      rgb = hex.scan(/../).map { |color| color.to_i(16) }
      dark = rgb.sum < 3 * 255 / 2.0

      additional_data[:dominant_color] = hex
      additional_data[:dark] = dark
    end

    file.update!(additional_data: additional_data)
  end
end
