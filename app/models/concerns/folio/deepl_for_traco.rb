# frozen_string_literal: true

module Folio::DeeplForTraco
  extend ActiveSupport::Concern

  class_methods do
    def deepl_configured?
      return @deepl_configured if defined?(@deepl_configured)

      @deepl_configured = ENV["DEEPL_API_KEY"].present? && begin
        require "deepl"
        DeepL.configure do |config|
          config.auth_key = ENV["DEEPL_API_KEY"]
          config.host = ENV.fetch("DEEPL_API_HOST", "https://api-free.deepl.com")
        end
        true
      rescue LoadError
        false
      end
    end

    def deepl_translates(*attributes)
      attributes.each do |attribute|
        define_method("#{attribute}=") do |val|
          I18n.available_locales.each do |l|
            return if send("#{attribute}_#{l}").present?

            if self.class.deepl_configured?
              translated = ::DeepL.translate(val, I18n.locale, l).text
            else
              translated = "#{val}(#{l.upcase})"
            end
            send("#{attribute}_#{l}=", translated)

          rescue ::DeepL::Exceptions::RequestError, ::DeepL::Exceptions::NotSupported, DeepL::Exceptions::Error => e
            Rails.logger.error("DeepL error: #{e.message}")
            send("#{attribute}_#{l}=", val)
          end
        end
      end
    end
  end

  included do
    before_validation :translate_slugs_if_new_record

    private
      def translate_slugs_if_new_record
        return unless new_record?

        current_locale = I18n.locale
        I18n.available_locales.each do |l|
          next if l == current_locale

          candidate_methods = send(friendly_id_config.base).reject { |c| c == :slug }

          I18n.with_locale(l) do
            if send(friendly_id_config.slug_column).blank?
              candidates = FriendlyId::Candidates.new(self, candidate_methods)
              slug = slug_generator.generate(candidates) || resolve_friendly_id_conflict(candidates)
              send "#{friendly_id_config.slug_column}=", slug
            end
          end
        end
      end
  end
end
