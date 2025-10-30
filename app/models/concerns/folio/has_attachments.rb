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

    attr_accessor :should_update_file_placement_counts
    before_save :update_file_placement_counts_if_needed

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
    validate :validate_files_usage_limits_if_publishing

    after_commit :update_file_usage_counts_on_publish_change,
                 if: :should_update_file_usage_counts?
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

      validates_associated placements_key, message: :invalid_file_placements

      has_many targets,
               source: :file,
               through: placements_key

      accepts_nested_attributes_for placements_key, allow_destroy: true, reject_if: proc { |attributes|
        if attributes["_destroy"].in?(["1", 1, true]) && attributes["id"].blank?
          true
        elsif attributes["file_id"] || attributes["file"]
          required_file_type = placement.constantize.reflections["file"].options[:class_name]
          file = attributes["file"] || Folio::File.find_by(id: attributes["file_id"])
          !file || !file.is_a?(required_file_type.constantize)
        elsif placement.constantize.folio_file_placement_supports_embed?
          folio_embed_data = if attributes["folio_embed_data"].is_a?(String)
            (JSON.parse(attributes["folio_embed_data"]) rescue {}) || {}
          elsif attributes["folio_embed_data"].is_a?(Hash)
            attributes["folio_embed_data"]
          else
            {}
          end

          folio_embed_data["active"] != true && folio_embed_data["active"] != "true"
        else
          attributes["id"].blank?
        end
      }

      # override setter so that it adds a "inside_nested_attributes" bool to each hash
      define_method("#{placements_key}_attributes=") do |attributes|
        attributes_array = if attributes.is_a?(Hash)
          attributes.values
        else
          Array(attributes)
        end

        new_attributes = attributes_array.filter_map do |hash|
          next hash unless hash.is_a?(Hash)
          { inside_nested_attributes: true }.merge(hash)
        end

        self.should_update_file_placement_counts = true

        # Convert back to original format if it was a hash
        final_attributes = if attributes.is_a?(Hash)
          new_attributes.each_with_index.to_h { |attrs, index| [index.to_s, attrs] }
        else
          new_attributes
        end

        super(final_attributes)
      end

      # Override collection setter to handle counter cache updates for has_many :through
      define_method("#{targets}=") do |new_files|
        # Track affected files before assignment to update their counters
        old_files = respond_to?(targets) ? send(targets).to_a : []

        # Call original setter (Rails handles placement creation/destruction)
        result = super(new_files)

        # Update counter cache for all affected files after the bulk operation
        # Use Arel for proper SQL generation and parameter binding
        affected_files = (old_files + Array(new_files)).uniq.compact
        affected_files.each do |file|
          # Manually recalculate and update the counter cache
          current_count = file.file_placements.count
          if file.file_placements_count != current_count
            # Use Arel to build a proper UPDATE statement
            table = file.class.arel_table
            update_manager = Arel::UpdateManager.new
            update_manager.table(table)
            update_manager.set([
              [table[:file_placements_count], current_count]
            ])
            update_manager.where(table[:id].eq(file.id))

            file.class.connection.execute(update_manager.to_sql)
            file.file_placements_count = current_count # Update in-memory value
          end
        end

        result
      end
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
        if attributes["_destroy"].in?(["1", 1, true]) && attributes["id"].blank?
          true
        elsif attributes["file_id"] || attributes["file"]
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

  def collect_all_placements
    self.class.folio_attachment_keys.flat_map do |type, keys|
      keys.flat_map do |association|
        type == :has_many ? send(association).to_a : send(association)
      end
    end.compact
  end

  def update_file_placement_counts_if_needed
    return unless should_update_file_placement_counts == true

    self.class.folio_attachment_keys[:has_many].each do |placement_key|
      if respond_to?("#{placement_key}_count=")
        count = send(placement_key).reject(&:marked_for_destruction?).size

        send("#{placement_key}_count=", count) if send("#{placement_key}_count") != count
      end
    end
  end

  def update_file_placement_count_if_needed!(placement_key:)
    return unless respond_to?("#{placement_key}_count=")

    count = send(placement_key).count

    if send("#{placement_key}_count") != count
      update_column("#{placement_key}_count", count)
    end
  end

  def soft_warnings_for_file_placements
    collect_all_placements
      .reject(&:marked_for_destruction?)
      .flat_map(&:console_warnings)
      .uniq
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

    def should_update_file_usage_counts?
      # Only for publishable objects that have published status
      return false unless respond_to?(:saved_changes)
      return false unless respond_to?(:published)

      saved_changes.key?("published")
    end

    def update_file_usage_counts_on_publish_change
      files = Folio::FilePlacement::Base
               .where(placement_id: id, placement_type: self.class.base_class.name)
               .includes(:file)
               .map(&:file)
               .uniq
               .compact

      files.each(&:update_published_usage_count!)
    end

    def validate_files_usage_limits_if_publishing
      # Only validate if object is being published
      return unless respond_to?(:published_changed?) && respond_to?(:published)
      return unless published_changed? && published == true

      get_files_with_usage_constraints.each do |file|
        if file.usage_limit_exceeded?
          errors.add(:base, I18n.t("errors.messages.cannot_publish_with_files_over_usage_limit",
                                   name: file.file_name,
                                   limit: file.attribution_max_usage_count))
        end

        unless file.can_be_used_on_site?(Folio::Current.site)
          errors.add(:base, I18n.t("errors.messages.cannot_publish_with_files_restricted_to_site",
                                   name: file.file_name,
                                   allowed_sites: file.allowed_sites.pluck(:title).join(", ")))
        end

        unless file.attribution_source.present?
          errors.add(:base, I18n.t("errors.messages.cannot_publish_with_files_without_media_source",
                                   name: file.file_name))
        end
      end
    end

    def get_files_with_usage_constraints
      # Get unique file types that have HasUsageConstraints concern
      file_types_with_constraints = Folio::FilePlacement::Base
                                      .joins("INNER JOIN folio_files ON folio_files.id = folio_file_placements.file_id")
        .where(placement_id: id, placement_type: self.class.base_class.name)
        .distinct
        .pluck("folio_files.type")
        .compact
        .select { |type| type.constantize.included_modules.include?(Folio::File::HasUsageConstraints) }
        .uniq

      return [] if file_types_with_constraints.empty?

      file_ids = Folio::File
        .joins(:file_placements)
        .where(
          type: file_types_with_constraints,
          file_placements: {
            placement_id: id,
            placement_type: self.class.base_class.name
          }
        )
        .distinct
        .pluck(:id)

      Folio::File.where(id: file_ids)
    end
end
