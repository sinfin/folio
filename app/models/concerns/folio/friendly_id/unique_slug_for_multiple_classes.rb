# frozen_string_literal: true

module Folio::FriendlyId::UniqueSlugForMultipleClasses
  extend ActiveSupport::Concern

  included do
    before_validation :set_unique_slug

    validate :validate_slug_through_classes,
             if: :slug_changed?
  end

  class_methods do
    def slug_additional_classes
      []
    end

    def slug_classes
      [base_class] + slug_additional_classes
    end

    def slug_class_names
      slug_classes.map { |klass| klass.model_name.human }.join(", ")
    end
  end

  private
    def slug_already_exists?(slug)
      slugs_scope = FriendlyId::Slug

      if defined?(self.class::FRIENDLY_ID_SCOPE)
        slugs_scope = slugs_scope.where(scope: "#{self.class::FRIENDLY_ID_SCOPE}:#{send(self.class::FRIENDLY_ID_SCOPE)}")
      end

      slugs_scope.where(sluggable_type: self.class.slug_classes.map(&:to_s), slug:).exists?
    end

    def validate_slug_through_classes
      return unless self.class.slug_additional_classes.any?

      exists = slug_already_exists?(slug)
      return unless exists

      errors.add(:slug, :not_uniqueness_through_classes, classes: self.class.slug_class_names)
    end

    def generate_next_slug
      slug_candidates_arr = slug_candidates.kind_of?(Array) ? slug_candidates : [slug_candidates]

      slug_candidates_arr.each do |candidate|
        candidate_slug = normalize_friendly_id(candidate.kind_of?(String) ? candidate : Array(candidate).map { |attr| send(attr) }.join("-"))
        next if candidate_slug.blank?

        exists = slug_already_exists? candidate_slug

        if !exists
          return candidate_slug
        end
      end

      "#{normalize_friendly_id(to_label)}-#{SecureRandom.uuid}"
    end

    def set_unique_slug
      return unless self.class.slug_additional_classes.any?
      return if read_attribute(:slug)

      self.slug = generate_next_slug
    end
end
