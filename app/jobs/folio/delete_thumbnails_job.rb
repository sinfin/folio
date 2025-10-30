# frozen_string_literal: true

class Folio::DeleteThumbnailsJob < Folio::ApplicationJob
  queue_as :slow

  unique :until_and_while_executing

  def perform(thumbnail_sizes)
    thumbnail_sizes.each do |size, values|
      Dragonfly.app.destroy(values[:uid]) if values[:uid]
      Dragonfly.app.destroy(values[:webp_uid]) if values[:webp_uid]
    end
  end
end
