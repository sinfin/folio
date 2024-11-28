# frozen_string_literal: true

module Folio::Console::Clonable
  extend ActiveSupport::Concern

  DEFAULT_RESET_ATTRIBUTES = [:published_at, :published]

  included do
    class_attribute :reference_associations, :duplicated_associations, :reset_attributes,
                    default: [], instance_writer: false

    self.reset_attributes = DEFAULT_RESET_ATTRIBUTES
  end

  class_methods do
    def references_original(*associations)
      validate_associations!(associations)
      self.reference_associations = associations
    end

    def duplicates_with_relations(*associations)
      validate_associations!(associations)
      self.duplicated_associations = associations
    end

    def reset_attributes_on_clone(*attributes)
      validate_attributes!(attributes)
      self.reset_attributes = DEFAULT_RESET_ATTRIBUTES + attributes
    end

      private
        def validate_associations!(associations)
          associations.each do |assoc|
              unless reflect_on_association(assoc)
                raise ArgumentError, I18n.t("activerecord.errors.clonable.association_not_found",
                                          association: assoc,
                                          model: self.name)
              end
            end
        end

        def validate_attributes!(attributes)
          attributes.each do |attr|
            unless column_names.include?(attr.to_s)
              raise ArgumentError, I18n.t("activerecord.errors.clonable.attribute_not_found",
                                        attribute: attr,
                                        model: self.name)
            end
          end
        end
  end

  def create_clone
    log("CLONING", :info)
    log(I18n.t("cloning.start", model: self.class.name, id: id))

    clone = deep_dup
    log(I18n.t("cloning.deep_dup_finished"))

    copy_references(clone)
    log(I18n.t("cloning.references_copied", references: self.class.reference_associations))

    duplicate_nested_records(clone)
    log(I18n.t("cloning.associations_duplicated", associations: self.class.duplicated_associations))

    reset_clone_attributes(clone)
    log(I18n.t("cloning.finished"))
    clone
rescue => e
  log(I18n.t("cloning.error", message: e.message), :error)
  log(e.backtrace.first(5).join("\n"), :error)
  raise
  end

    private
      def reset_clone_attributes(clone)
        self.class.reset_attributes.each do |attr|
          clone[attr] = nil if clone.has_attribute?(attr)
        end
      end

      def copy_references(cloned)
        return unless self.class.reference_associations.present?

        self.class.reference_associations.each do |assoc|
          cloned.public_send("#{assoc}=", public_send(assoc))
        end
      end

      def duplicate_nested_records(cloned)
        return unless self.class.duplicated_associations.present?

        self.class.duplicated_associations.each do |assoc|
          cloned.public_send("#{assoc}=", clone_associated_records(assoc))
        end
      end

      def clone_associated_records(association)
        originals = public_send(association)
        originals = [originals] unless originals.is_a?(ActiveRecord::Relation)

        clones = originals.map do |orig|
          clone = orig.deep_dup

          if orig.class.reflect_on_all_associations.present?
            orig.class.reflect_on_all_associations.each do |association|
              clone_association(orig, clone, association)
            end
          end

          clone
        end

        originals.is_a?(ActiveRecord::Relation) ? clones : clones.first
      end

      def clone_association(original, clone, association)
        if association.macro == :has_many
          clone_has_many_association(original, clone, association)
        else
          clone_single_association(original, clone, association)
        end
      end

      def clone_has_many_association(original, clone, association)
        return if [:files, :placements].include?(association.name)
        associated_records = original.public_send(association.name)
        associated_records = associated_records.map { |r| r.deep_dup } unless self.class.reference_associations.include?(association.name)
        clone.association(association.name).build(associated_records.map(&:attributes))
      end

      def clone_single_association(original, clone, association)
        associated_record = original.public_send(association.name)
        return unless associated_record

        associated_record_dup = self.class.reference_associations.include?(association.name) ?
                              associated_record :
                              associated_record.deep_dup

        clone.public_send("#{association.name}=", associated_record_dup)
      end

      def log(message, level = :info)
        if Rails.env.development? && Rails.logger
          Rails.logger.tagged("CLONING") do
            Rails.logger.public_send(level, message)
          end
        else
          puts "[CLONING] #{message}"
        end
      end
end
