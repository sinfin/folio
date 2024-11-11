# frozen_string_literal: true

class Folio::PregenerateThumbnails::CheckJob < Folio::ApplicationJob
  queue_as :slow

  # Discard if attachmentable no longer exists
  discard_on ActiveJob::DeserializationError

  def perform(attachmentable)
    if attachmentable && attachmentable.respond_to?(:file_placements)
      attachmentable.file_placements.find_each do |file_placement|
        file_placement.try(:pregenerate_thumbnails)
      end
    end
  end
end
