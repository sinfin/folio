# frozen_string_literal: true

class Folio::DestroyThumbnailUidsJob < Folio::ApplicationJob
  def perform(uids)
    Array(uids).uniq.each do |uid|
      next if uid.blank?
      begin
        Dragonfly.app.datastore.destroy(uid)
      rescue StandardError => e
        Rails.logger.error("Failed to destroy old thumbnail UID #{uid}: #{e.message}")
      end
    end
  end
end
