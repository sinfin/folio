# frozen_string_literal: true

class Folio::Files::AfterSaveJob < Folio::ApplicationJob
  queue_as :slow

  # Discard if file no longer exists
  discard_on ActiveJob::DeserializationError

  # use SQL commands only!
  # save/update would cause an infinite loop as this is hooked in after_save
  def perform(file)
    return if Rails.env.test? && !Rails.application.config.try(:folio_testing_after_save_job)

    placements = file.file_placements

    file.update_column(:file_placements_size, placements.size)

    # touch placements to bust cache
    placements.find_each do |placement|
      if placement.placement
        placement.placement.touch
      end
    end
  end
end
