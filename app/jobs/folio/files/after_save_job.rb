# frozen_string_literal: true

class Folio::Files::AfterSaveJob < Folio::ApplicationJob
  queue_as :slow

  # Discard if file no longer exists
  discard_on ActiveJob::DeserializationError

  # use SQL commands only!
  # save/update would cause an infinite loop as this is hooked in after_save
  def perform(file)
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
