# frozen_string_literal: true

class Folio::MigrateThumbsToRemoteUrlJob < Folio::ApplicationJob
  queue_as :slow

  discard_on ActiveJob::DeserializationError

  unique :until_and_while_executing

  def perform(image)
    return if image.file_mime_type.include?("svg")

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
        thumbnail_sizes[size] = data.merge(url: Folio::S3.url_rewrite(Dragonfly.app.datastore.url_for(data[:uid])))
        changed = true
      end

      if changed
        image.thumbnail_sizes = thumbnail_sizes
        image.save!(validate: false)
      end
    end
  end
end
