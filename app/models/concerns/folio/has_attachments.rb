# frozen_string_literal: true

module Folio::HasAttachments
  extend ActiveSupport::Concern

  included do
    has_many :file_placements, class_name: "Folio::FilePlacement::Base",
                               as: :placement,
                               dependent: :destroy

    has_many :files,
             source: :file,
             class_name: "Folio::File",
             through: :file_placements

    after_save :run_file_placements_after_save!

    has_many_placements(:images,
                        placements_key: :image_placements,
                        placement: "Folio::FilePlacement::Image")

    has_many_placements(:documents,
                        placements_key: :document_placements,
                        placement: "Folio::FilePlacement::Document")

    has_one_placement(:cover,
                      placement_key: :cover_placement,
                      placement: "Folio::FilePlacement::Cover")

    has_one_placement(:document,
                      placement_key: :document_placement,
                      placement: "Folio::FilePlacement::SingleDocument")
  end

  class_methods do
    def has_many_placements(targets, placement:, placements_key: nil)
      placements_key ||= "#{targets.to_s.singularize}_placements".to_sym

      has_many placements_key,
               -> { ordered },
               class_name: placement,
               as: :placement,
               inverse_of: :placement,
               dependent: :destroy,
               foreign_key: :placement_id

      has_many targets,
               source: :file,
               through: placements_key

      accepts_nested_attributes_for placements_key, allow_destroy: true
    end

    def has_one_placement(target, placement:, placement_key: nil)
      placement_key ||= "#{target}_placement".to_sym

      has_one placement_key,
              class_name: placement,
              as: :placement,
              inverse_of: :placement,
              dependent: :destroy,
              foreign_key: :placement_id

      has_one target,
              source: :file,
              through: placement_key

      accepts_nested_attributes_for placement_key, allow_destroy: true
    end
  end

  private
    def run_file_placements_after_save!
      file_placements.find_each(&:run_after_save_job!)
    end
end
