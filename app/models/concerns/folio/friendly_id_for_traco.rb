# frozen_string_literal: true

module Folio::FriendlyIdForTraco
  extend ActiveSupport::Concern

  included do
    extend FriendlyId

    if defined?(self::FRIENDLY_ID_SCOPE)
      friendly_id :slug_candidates, use: %i[slugged history simple_i18n scoped], scope: self::FRIENDLY_ID_SCOPE

      I18n.available_locales.each do |locale|
        validates "slug_#{locale}".to_sym,
                  presence: true,
                  uniqueness: { scope: self::FRIENDLY_ID_SCOPE },
                  format: { with: /[a-z][0-9a-z-]+/ }
      end
    else
      friendly_id :slug_candidates, use: %i[slugged history simple_i18n]

      I18n.available_locales.each do |locale|
        validates "slug_#{locale}".to_sym,
                  presence: true,
                  uniqueness: true,
                  format: { with: /[a-z][0-9a-z-]+/ }
      end
    end

    before_validation :set_missing_slugs
    before_validation :strip_and_downcase_slugs
  end

  private
    def slug_candidates
      to_label
    end

    def strip_and_downcase_slugs
      I18n.available_locales.each do |locale|
        slug_column = "slug_#{locale}"

        if send(slug_column).present?
          send("#{slug_column}=", send(slug_column).strip.downcase.parameterize)
        end
      end
    end

    def set_missing_slugs
      filled = nil

      I18n.available_locales.each do |locale|
        slug_column = "slug_#{locale}"

        if filled.nil? && send(slug_column).present?
          filled = send(slug_column)
        end
      end

      if filled.present?
        I18n.available_locales.each do |locale|
          slug_column = "slug_#{locale}"

          if send(slug_column).blank?
            send("#{slug_column}=", filled)
          end
        end
      end
    end
end
