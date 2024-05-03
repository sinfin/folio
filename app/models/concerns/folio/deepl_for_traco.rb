# frozen_string_literal: true

require "deepl"

module Folio::DeeplForTraco
  extend ActiveSupport::Concern

  included do
    DeepL.configure do |config|
      config.auth_key = ENV.fetch("DEEPL_API_KEY", nil)
      config.host = ENV.fetch("DEEPL_API_HOST", "https://api-free.deepl.com")
    end

    before_validation :translate_slugs_if_new_record
  end

  class_methods do
    def deepl_translates(*attributes)
      attributes.each do |attribute|
        define_method("#{attribute}=") do |val|
          I18n.available_locales.each do |l|
            return if send("#{attribute}_#{l}").present?

            translated = ::DeepL.translate(val, I18n.locale, l).text
            send("#{attribute}_#{l}=", translated)

          rescue ::DeepL::Exceptions::RequestError, ::DeepL::Exceptions::NotSupported, DeepL::Exceptions::Error => e
            Rails.logger.error("DeepL error: #{e.message}")
            send("#{attribute}_#{l}=", val)
          end
        end
      end
    end
  end

  def translate_slugs_if_new_record
    return unless new_record?

    current_locale = I18n.locale
    I18n.available_locales.each do |l|
      next if l == current_locale

      I18n.with_locale(l) { set_slug }
    end
  end
end
