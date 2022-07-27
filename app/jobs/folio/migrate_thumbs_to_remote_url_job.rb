# frozen_string_literal: true

class Folio::MigrateThumbsToRemoteUrlJob < Folio::ApplicationJob
  queue_as :slow

  def perform(image)
    return if /svg/.match?(image.file_mime_type)
    return if image.animated_gif?

    # need to reload here because of parallel jobs
    image.reload
    thumbnail_sizes = image.thumbnail_sizes
    return unless thumbnail_sizes.present?

    image.with_lock do
      changed = false

      thumbnail_sizes.each do |size, data|
        next unless data[:uid]
        next unless data[:url]
        next unless data[:url].start_with?("/media")
        thumbnail_sizes[size] = data.merge(url: Dragonfly.app.datastore.url_for(data[:uid]))
        changed = true
      end

      if changed
        image.update!(thumbnail_sizes:)
      end
    end
  end
end
