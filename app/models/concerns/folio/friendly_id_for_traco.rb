# frozen_string_literal: true

module Folio::FriendlyIdForTraco
  extend ActiveSupport::Concern

  included do
    include Folio::FriendlyId::History
    include Folio::FriendlyId::SlugValidation::MultipleClasses

    if defined?(self::FRIENDLY_ID_SCOPE)
      friendly_id :slug_candidates, use: %i[slugged history simple_i18n scoped], scope: self::FRIENDLY_ID_SCOPE

      I18n.available_locales.each do |locale|
        validates "slug_#{locale}".to_sym,
                  presence: true,
                  uniqueness: { scope: self::FRIENDLY_ID_SCOPE },
                  format: { with: /[a-z][0-9a-z-]+/ },
                  if: -> { errors["slug_#{locale}".to_sym].blank? }
      end
    else
      friendly_id :slug_candidates, use: %i[slugged history simple_i18n]

      I18n.available_locales.each do |locale|
        validates "slug_#{locale}".to_sym,
                  presence: true,
                  uniqueness: true,
                  format: { with: /[a-z][0-9a-z-]+/ },
                  if: -> { errors["slug_#{locale}".to_sym].blank? }
      end
    end

    before_validation :set_missing_slugs
    before_validation :strip_and_downcase_slugs

    # Get the instance's friendly_id.
    # overriden from https://github.com/norman/friendly_id/blob/c288abb863cc0ad3a57131f1047542969776ecb7/lib/friendly_id/base.rb#L257
    # we need to handle changes so that forms don't lead to a non-existent slug
    def friendly_id
      column_name = friendly_id_config.query_field

      if changed? && changed_attributes.present? && changed_attributes[column_name].present?
        changed_attributes[column_name]
      else
        super
      end
    end
  end

  private
    def slug_candidates
      %i[slug to_label]
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
