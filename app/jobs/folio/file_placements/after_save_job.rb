# frozen_string_literal: true

class Folio::FilePlacements::AfterSaveJob < Folio::ApplicationJob
  queue_as :slow

  # Discard if file_placement no longer exists
  discard_on ActiveJob::DeserializationError

  # use SQL commands only!
  # save/update would cause an infinite loop as this is hooked in after_save
  def perform(file_placement)
    return if Rails.env.test? && !Rails.application.config.try(:folio_testing_after_save_job)

    update_placement_title(file_placement)
  end

  def update_placement_title(file_placement)
    placement = file_placement.placement

    if placement.present?
      if placement.class < Folio::Atom::Base
        source = placement.placement
      else
        source = placement
      end

      I18n.with_locale(Rails.application.config.folio_console_locale) do
        title = source.try(:to_label) ||
                source.try(:title) ||
                source.try(:name)

        pl_title = [source.class.model_name.human, title].join(" - ")

        if title.present?
          file_placement.update_columns(placement_title: pl_title,
                                        placement_title_type: source.class.to_s)
        end
      end
    end
  end
end
