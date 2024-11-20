# frozen_string_literal: true

module Folio::FriendlyId::SlugValidation::MultipleClasses
  extend ActiveSupport::Concern

  included do
    before_validation :slug_validation_set_unique_slug

    validate :slug_validation_validate_slug_across_classes
  end

  class_methods do
    def slug_validation_additional_classes
      []
    end

    def slug_validation_classes
      [slug_validation_class] + slug_validation_additional_classes
    end

    def slug_validation_class
      base_class
    end
  end

  private
    def slug_validation_friendly_id_slug_from_given_classes_for(slug)
      slugs_scope = FriendlyId::Slug

      if defined?(self.class::FRIENDLY_ID_SCOPE)
        slugs_scope = slugs_scope.where(scope: "#{self.class::FRIENDLY_ID_SCOPE}:#{send(self.class::FRIENDLY_ID_SCOPE)}")
      end

      friendy_id_slugs = slugs_scope.where(sluggable_type: self.class.slug_validation_classes.map { |slug_class| slug_class.slug_validation_class.to_s }, slug:)
                                    .where.not(sluggable: self)
                                    .includes(:sluggable)

      friendy_id_slugs.find do |friendy_id_slug|
        self.class.slug_validation_classes.any? do |klass|
          friendy_id_slug.sluggable.is_a?(klass)
        end
      end
    end

    def slug_validation_slug_already_exists?(slug)
      slug_validation_friendly_id_slug_from_given_classes_for(slug).present?
    end

    def slug_validation_validate_slug_across_classes
      return if self.class.slug_validation_additional_classes.blank?
      return if errors.present? && errors[:slug].present?

      friendly_id_slug = slug_validation_friendly_id_slug_from_given_classes_for(slug)
      return unless friendly_id_slug && friendly_id_slug.sluggable

      errors.add(:slug,
                 :slug_not_unique_across_classes,
                 sluggable_name: friendly_id_slug.sluggable.to_label,
                 sluggable_type: friendly_id_slug.sluggable.class.model_name.human)
    end

    def slug_validation_generate_next_slug
      slug_candidates_arr = slug_candidates.kind_of?(Array) ? slug_candidates : [slug_candidates]

      slug_candidates_arr.each do |candidate|
        candidate_slug = normalize_friendly_id(candidate.kind_of?(String) ? candidate : Array(candidate).map { |attr| send(attr) }.join("-"))
        next if candidate_slug.blank?

        exists = slug_validation_slug_already_exists? candidate_slug

        if !exists
          return candidate_slug
        end
      end

      "#{normalize_friendly_id(to_label)}-#{SecureRandom.uuid}"
    end

    def slug_validation_set_unique_slug
      return if self.class.slug_validation_additional_classes.blank?
      return if read_attribute(:slug)

      self.slug = slug_validation_generate_next_slug
    end
end
