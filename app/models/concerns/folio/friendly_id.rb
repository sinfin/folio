# frozen_string_literal: true

module Folio::FriendlyId
  extend ActiveSupport::Concern

  included do
    include Folio::FriendlyId::History
    before_validation :set_unique_slug
    validate :validate_slug_through_classes, if: :slug_changed?

    if defined?(self::FRIENDLY_ID_SCOPE)
      friendly_id :slug_candidates, use: %i[slugged history scoped], scope: self::FRIENDLY_ID_SCOPE

      validates :slug,
                presence: true,
                uniqueness: { scope: self::FRIENDLY_ID_SCOPE },
                format: { with: /[0-9a-z-]+/ }
    else
      friendly_id :slug_candidates, use: %i[slugged history]

      validates :slug,
                presence: true,
                uniqueness: true,
                format: { with: /[0-9a-z-]+/ }
    end

    before_validation :strip_and_downcase_slug
  end

  class_methods do
    def slug_additional_classes
      []
    end

    def slug_classes
      [self] + slug_additional_classes
    end

    def slug_classes_names
      slug_classes.map { |klass| klass.model_name.human }.join(", ")
    end
  end

  private
    def check_slug_uniqueness(slug)
      exists = self.class.slug_classes.any? do |klass|
        klass.exists?(slug:)
      end
      exists
    end

    def validate_slug_through_classes
      exists = check_slug_uniqueness slug
      return unless exists
      errors.add(:slug, :not_uniqueness_through_classes, classes: self.class.slug_classes_names)
    end

    def generate_next_slug
      slug_candidates_arr = slug_candidates.kind_of?(Array) ? slug_candidates : [slug_candidates]
      slug_candidates_arr.each do |candidate|
        candidate_slug = normalize_friendly_id(candidate.kind_of?(String) ? candidate : Array(candidate).map { |attr| send(attr) }.join("-"))
        next if candidate_slug.blank?
        exists = check_slug_uniqueness candidate_slug
        if !exists
          return candidate_slug
        end
      end
      "#{normalize_friendly_id(to_label)}-#{SecureRandom.uuid}"
    end

    def set_unique_slug
      return if read_attribute(:slug)
      self.slug = generate_next_slug
    end

    def slug_candidates
      # fixes https://github.com/norman/friendly_id/issues/983
      %i[slug to_label]
    end

    def strip_and_downcase_slug
      if slug.present?
        self.slug = slug.strip.downcase.parameterize
      end
    end
end
