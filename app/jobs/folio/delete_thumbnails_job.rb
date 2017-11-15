# frozen_string_literal: true

module Folio
  class DeleteThumbnailsJob < ApplicationJob
    queue_as :slow

    def perform(thumbnail_sizes)
      thumbnail_sizes.each do |size, values|
        Dragonfly.app.destroy(values[:uid])
      end
    end
  end
end
