# frozen_string_literal: true

class Folio::MigrateThumbsToRemoteUrlJob < Folio::ApplicationJob
  queue_as :slow

  discard_on ActiveJob::DeserializationError

  unique :until_and_while_executing,
         lock_ttl: 1.minute,
         on_conflict: :log

  def perform(image)
    return if image.file_mime_type.include?("svg")
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
        thumbnail_sizes[size] = data.merge(url: Folio::S3.url_rewrite(Dragonfly.app.datastore.url_for(data[:uid])))
        changed = true
      end

      if changed
        image.update!(thumbnail_sizes:)
      end
    end
  end

  # Define what makes a job unique - only image ID matters for deduplication
  def lock_key_arguments
    image = arguments[0]

    # Handle both direct objects and GlobalID serialized objects
    if image.respond_to?(:to_global_id)
      [image.to_global_id.to_s]
    elsif image.is_a?(Hash) && image["_aj_globalid"]
      [image["_aj_globalid"]]
    else
      # Fallback - use first argument
      [image]
    end
  end
end
