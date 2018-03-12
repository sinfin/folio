# frozen_string_literal: true

module Folio
  class ThumbnailTimeout < StandardError; end

  class ThumbnailsController < ApplicationController
    TIMEOUT = Rails.env.test? ? 0.5 : 5
    TIME_LIMIT = 60.freeze

    def show
      thumb_url = nil
      start_time = Time.now

      begin
        image = Image.find(params[:image_id])
        thumb = image.existing_thumb(params[:size].gsub('___', '#'))
        thumb_url = thumb.url if thumb

        puts "Waiting for image #{image.id} for #{Time.now - start_time}" if Rails.env.development?

        break if thumb_url
        raise ThumbnailTimeout if (Time.now - start_time) > TIME_LIMIT
        sleep TIMEOUT
      end while !thumb_url

      redirect_to thumb_url

    rescue ThumbnailTimeout
      head 408
    end
  end
end
