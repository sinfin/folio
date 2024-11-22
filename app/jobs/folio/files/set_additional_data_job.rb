# frozen_string_literal: true

class Folio::Files::SetAdditionalDataJob < Folio::ApplicationJob
  queue_as :slow

  discard_on(ActiveJob::DeserializationError) do |job, e|
    Raven.capture_exception(e) if defined?(Raven)
    Sentry.capture_exception(e) if defined?(Sentry)
  end

  def perform(file_model)
    additional_data = file_model.additional_data || {}

    image = Vips::Image.new_from_file(file_model.file.path)

    if file_model.gif?
      begin
        Vips::Image.new_from_file(file_model.file.path, page: 1)
        additional_data[:animated] = true
      rescue Vips::Error
        additional_data[:animated] = false
      end
    end

    unless file_model.jpg?
      image = Vips::Image.jpegload_buffer(image.jpegsave_buffer)
    end

    # handle monocolored pngs and gifs
    # for `image.stats`` see https://www.libvips.org/API/current/libvips-arithmetic.html#vips-stats
    # stats.getpoint(index_of_type_of_stats, rbgA_band) => [value]
    # type_of_stats [minimum,
    #                maximum,
    #                sum,
    #                sum of squares,
    #                mean,
    #                standard deviation,
    #                x coordinate of minimum,
    #                y coordinate of minimum,
    #                x coordinate of maximum,
    #                y coordinate of maximum]
    last = 0
    mean_color_rgb = Array.new(3) do |i|
      last = image.stats.getpoint(4, i + 1)[0]
      rescue Vips::Error
        last
    end

    additional_data[:dominant_color] = "#%02X%02X%02X" % mean_color_rgb # floats to hexes
    additional_data[:dark] = mean_color_rgb.sum < 3 * 127.0

    file_model.update!(additional_data:)
  end
end
