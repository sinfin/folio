# frozen_string_literal: true

class Folio::Console::Api::ImagesController < Folio::Console::Api::BaseController
  include Folio::Console::Api::FileControllerBase
  folio_console_controller_for "Folio::Image"

  def update_file_thumbnail
    thumb_key = params.require(:thumb_key)
    x = params.require(:x)
    y = params.require(:y)

    thumb = @image.thumbnail_sizes[thumb_key]

    if thumb[:x] != x || thumb[:y] != y
      @image.thumb(thumb_key, immediate: true, force: true, x: x, y: y)
    end

    render_record(@image.reload, Folio::Console::FileSerializer)
  end

  def destroy_file_thumbnail
    thumb_key = params.require(:thumb_key)
    thumb = @image.thumbnail_sizes[thumb_key]

    if thumb
      Folio::DeleteThumbnailsJob.perform_later({ thumb_key => thumb })
      @image.update(thumbnail_sizes: @image.thumbnail_sizes.without(thumb_key))
    end

    render_record(@image, Folio::Console::FileSerializer)
  end
end
