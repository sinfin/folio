# frozen_string_literal: true

class Folio::DeleteThumbnailsJob < Folio::ApplicationJob
  queue_as :slow

  adapter_aware_sidekiq_options(
    lock: :until_and_while_executing,
    lock_ttl: 1.minute.to_i,
    on_conflict: {
      client: :reject,
      server: :raise
    }
  )

  def perform(thumbnail_sizes)
    thumbnail_sizes.each do |size, values|
      Dragonfly.app.destroy(values[:uid]) if values[:uid]
      Dragonfly.app.destroy(values[:webp_uid]) if values[:webp_uid]
    end
  end
end
