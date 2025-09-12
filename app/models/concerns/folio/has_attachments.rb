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
    after_save_commit :run_pregenerate_thumbnails_check_job_if_needed

    has_many_placements(:tiptap_files,
                        placements_key: :tiptap_placements,
                        placement: "Folio::FilePlacement::Tiptap")

    has_many_placements(:images,
                        placements_key: :image_placements,
                        placement: "Folio::FilePlacement::Image")

    has_many_placements(:image_or_embeds,
                        placements_key: :image_or_embed_placements,
                        placement: "Folio::FilePlacement::ImageOrEmbed")

    has_many_placements(:documents,
                        placements_key: :document_placements,
                        placement: "Folio::FilePlacement::Document")

    has_one_placement(:cover,
                      placement_key: :cover_placement,
                      placement: "Folio::FilePlacement::Cover")

    has_one_placement(:audio_cover,
                      placement_key: :audio_cover_placement,
                      placement: "Folio::FilePlacement::AudioCover")

    has_one_placement(:video_cover,
                      placement_key: :video_cover_placement,
                      placement: "Folio::FilePlacement::VideoCover")

    has_one_placement(:document,
                      placement_key: :document_placement,
                      placement: "Folio::FilePlacement::SingleDocument")

    has_one_placement(:og_image,
                      placement_key: :og_image_placement,
                      placement: "Folio::FilePlacement::OgImage")

    attr_accessor :dont_run_file_placements_after_save

    validate :validate_file_placements_if_needed
  end

  class_methods do
    def has_folio_attachments?
      true
    end

    def has_many_placements(targets, placement:, placements_key: nil)
      placements_key ||= "#{targets.to_s.singularize}_placements".to_sym

      has_many placements_key,
               -> { ordered },
               class_name: placement,
               as: :placement,
               inverse_of: :placement,
               dependent: :destroy,
               foreign_key: :placement_id

      validates_associated placements_key, message: :invalid_file_placement

      has_many targets,
               source: :file,
               through: placements_key

      accepts_nested_attributes_for placements_key, allow_destroy: true, reject_if: proc { |attributes|
        if attributes["file_id"] || attributes["file"]
          required_file_type = placement.constantize.reflections["file"].options[:class_name]
          file = attributes["file"] || Folio::File.find_by(id: attributes["file_id"])
          !file || !file.is_a?(required_file_type.constantize)
        else
          attributes["id"].blank?
        end
      }
    end

    def has_one_placement(target, placement:, placement_key: nil)
      placement_key ||= "#{target}_placement".to_sym

      has_one placement_key,
              class_name: placement,
              as: :placement,
              inverse_of: :placement,
              dependent: :destroy,
              foreign_key: :placement_id

      validates_associated placement_key, message: :invalid_file_placement

      has_one target,
              source: :file,
              through: placement_key

      accepts_nested_attributes_for placement_key, allow_destroy: true, reject_if: proc { |attributes|
        if attributes["file_id"] || attributes["file"]
          required_file_type = placement.constantize.reflections["file"].options[:class_name]
          file = attributes["file"] || Folio::File.find_by(id: attributes["file_id"])
          !file || !file.is_a?(required_file_type.constantize)
        else
          attributes["id"].blank?
        end
      }
    end

    def folio_attachments_first_image_as_cover
      after_save :update_cover_placement

      define_method :update_cover_placement do
        if ip = image_placements.reload.first
          if cover_placement
            if cover_placement.file_id != ip.file_id
              cover_placement.update(file_id: ip.file_id)
            end
          else
            create_cover_placement(file_id: ip.file_id)
          end
        elsif cover_placement
          cover_placement.destroy
        end
      end

      private :update_cover_placement
    end

    def run_pregenerate_thumbnails_check_job?
      false
    end

    def folio_attachment_keys
      h = { has_one: [], has_many: [] }

      reflect_on_all_associations.each do |reflection|
        if reflection.options && reflection.options[:class_name]
          next if reflection.name == :file_placements
          klass = reflection.options[:class_name].safe_constantize

          if klass && klass <= Folio::FilePlacement::Base
            if reflection.is_a?(ActiveRecord::Reflection::HasManyReflection)
              h[:has_many] << reflection.name
            else
              h[:has_one] << reflection.name
            end
          end
        end
      end

      h
    end
  end

  def og_image_with_fallback
    og_image.presence || cover
  end

  def should_validate_file_placements_attribution_if_needed?
    return false unless Rails.application.config.folio_files_require_attribution

    # only validate if published by default
    read_attribute(:published) == true
  end

  def should_validate_file_placements_alt_if_needed?
    return false unless Rails.application.config.folio_files_require_alt

    # only validate if published by default
    read_attribute(:published) == true
  end

  def should_validate_file_placements_description_if_needed?
    return false unless Rails.application.config.folio_files_require_description

    # only validate if published by default
    read_attribute(:published) == true
  end

  private
    def run_file_placements_after_save!
      return if dont_run_file_placements_after_save
      file_placements.find_each(&:run_after_save_job!)
    end

    def run_pregenerate_thumbnails_check_job_if_needed
      return unless self.class.run_pregenerate_thumbnails_check_job?
      Folio::PregenerateThumbnails::CheckJob.perform_later(self)
    end

    def validate_file_placements_if_needed
      all_placements_ary = []
      has_invalid_file_placements = false

      self.class.folio_attachment_keys.each do |type, keys|
        if type == :has_many
          keys.each do |association|
            all_placements_ary += send(association).to_a
          end
        else
          keys.each do |association|
            placement = send(association)
            all_placements_ary << placement if placement
          end
        end
      end

      if should_validate_file_placements_attribution_if_needed?
        all_placements_ary.each do |placement|
          placement.validate_attribution_if_needed
          if placement.errors[:file].present?
            has_invalid_file_placements = true
          end
        end
      end

      if should_validate_file_placements_alt_if_needed?
        all_placements_ary.each do |placement|
          placement.validate_alt_if_needed
          if placement.errors[:file].present?
            has_invalid_file_placements = true
          end
        end
      end

      if should_validate_file_placements_description_if_needed?
        all_placements_ary.each do |placement|
          placement.validate_description_if_needed
          if placement.errors[:file].present?
            has_invalid_file_placements = true
          end
        end
      end

      if has_invalid_file_placements
        errors.add(:base, :has_invalid_file_placements)
      end
    end
end
