# frozen_string_literal: true

module Folio
  class ThumbnailTimeout < StandardError; end

  class ThumbnailsController < ApplicationController
    TIMEOUT = Rails.env.test? ? 0.5 : 5

    def show
      thumb_url = nil
      start_time = Time.now

      begin
        image = Image.find(params[:image_id])
        thumb = image.existing_thumb(params[:size].gsub('___', '#'))
        thumb_url = thumb.url if thumb
        break if thumb_url
        raise ThumbnailTimeout if (Time.now - start_time) > 60
        sleep TIMEOUT
      end while !thumb_url

      redirect_to thumb_url

    rescue ThumbnailTimeout
      render nothing: true, status: 408
    end
  end
end
