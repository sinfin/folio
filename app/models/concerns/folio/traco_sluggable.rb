# frozen_string_literal: true

module Folio::TracoSluggable
  extend ActiveSupport::Concern

  included do
    after_save :set_missing_slugs
  end

  private

    def set_missing_slugs
      I18n.available_locales.each do |locale|
        if send("slug_#{locale}").blank?
          I18n.with_locale(locale) { save! }
        end
      end
    end
end
