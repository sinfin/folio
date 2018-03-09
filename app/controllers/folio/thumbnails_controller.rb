# frozen_string_literal: true

require_dependency 'folio/application_controller'

module Folio
  class ThumbnailTimeout < StandardError; end

  class ThumbnailsController < ApplicationController
    def show
      thumb_url = nil
      start_time = Time.now

      begin
        thumb_url = Folio::Image.find(params[:id]).thumb(params[:size], true)
        break if thumb_url
        raise Folio::ThumbnailTimeout if (Time.now - start_time) > 60
        sleep 3
      rescue Folio::ThumbnailTimeout
        render nothing: true, status: 408
      end while !thumb_url

      redirect_to thumb_url
    end
  end
end
