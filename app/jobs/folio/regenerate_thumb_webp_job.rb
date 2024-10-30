# frozen_string_literal: true

class Folio::RegenerateThumbWebpJob < Folio::ApplicationJob
  queue_as :slow

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
        Dragonfly.app.destroy(data[:webp_uid]) if data[:webp_uid]
        thumbnail_sizes[size] = add_webp_thumb(image, size, data)
        changed = true
      end

      if changed
        image.update!(thumbnail_sizes:)
      end
    end
  end

  private
    def add_webp_thumb(image, size, data)
      thumbnail = Dragonfly.app.fetch(data[:uid])

      webp = thumbnail.convert_to_webp
      webp.name = Pathname(webp.name || "webp").sub_ext(".webp").to_s
      webp_uid = webp.store

      data.merge(
        webp_uid:,
        webp_url: Folio::S3.url_rewrite(Dragonfly.app.datastore.url_for(webp_uid)),
        webp_signature: webp.signature,
      )
    end
end
