# frozen_string_literal: true

module Folio
  class ThumbnailTimeout < StandardError; end

  class ThumbnailsController < ApplicationController
    def show
      image = Image.find(params[:image_id])
      size = params[:size].gsub('___', '#')
      thumb = image.thumb(size)

      if thumb[:working_since]
        render plain: "http://dummyimage.com/#{size}/FFF/000.png&text=Generating…", status: 202
      else
        render plain: thumb.url
      end
    end
  end
end
