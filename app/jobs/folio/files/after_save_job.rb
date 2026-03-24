# frozen_string_literal: true

class Folio::Files::AfterSaveJob < Folio::ApplicationJob
  queue_as :slow

  # Discard if file no longer exists
  discard_on ActiveJob::DeserializationError

  unique :until_and_while_executing

  # use SQL commands only!
  # save/update would cause an infinite loop as this is hooked in after_save
  def perform(file, changed_attrs = {})
    return if Rails.env.test? && !Rails.application.config.try(:folio_testing_after_save_job)

    placements = file.file_placements

    file.update_column(:file_placements_count, placements.size)

    # Sync description/alt/headline to placements if file metadata changed
    if changed_attrs.present?
      sync_metadata_to_placements(file, placements, changed_attrs)
    end

    # touch placements to bust cache
    placements.find_each do |placement|
      if placement.placement
        placement.placement.touch
      end
    end
  end

  private

    def sync_metadata_to_placements(file, placements, changed_attrs)
      if changed_attrs.key?("description")
        old_desc, new_desc = changed_attrs["description"]
        placements.where(description: [old_desc, nil, ""]).update_all(description: new_desc)
      end

      if changed_attrs.key?("alt")
        old_alt, new_alt = changed_attrs["alt"]
        placements.where(alt: [old_alt, nil, ""]).update_all(alt: new_alt)
      end

      if changed_attrs.key?("headline")
        old_headline, new_headline = changed_attrs["headline"]
        placements.where(title: [old_headline, nil, ""]).update_all(title: new_headline)
      end
    end
end
