# frozen_string_literal: true

module Folio
  module HtmlSanitization
    class Sanitizer
      DEFAULT_ATTRIBUTE_CONFIG = :string

      def initialize(record:)
        @record = record
      end

      def self.sanitize(record:)
        new(record:).sanitize
      end

      def sanitize
        return unless @record.folio_html_sanitization_config[:enabled]

        if @record.is_a?(Folio::Atom::Base)
          sanitize_atom
        else
          sanitize_record
        end

        @record
      end

      private
        def attributes_config
          @attributes_config ||= @record.folio_html_sanitization_config[:attributes]
        end

        def sanitize_attribute(attribute:)
          value = @record.send(attribute)
          return if value.blank?
          return unless value.is_a?(String)

          attribute_config = attributes_config[attribute] || DEFAULT_ATTRIBUTE_CONFIG

          if attribute_config.is_a?(Proc)
            sanitize_attribute_via_proc(attribute:, value:, proc: attribute_config)
          else
            case attribute_config
            when :unsafe_html
              # No sanitization for unsafe_html
            when :richtext
              sanitize_attribute_as_richtext(attribute:, value:)
            when :string
              sanitize_attribute_as_string(attribute:, value:)
            else
              raise ArgumentError, "Unknown attribute config: #{attribute_config.inspect}"
            end
          end
        end

        def sanitize_attribute_as_richtext(attribute:, value:)
          sanitized_value = ActionController::Base.helpers.sanitize(value)

          if value != sanitized_value
            @record.send("#{attribute}=", sanitized_value)
            log(attribute:, message: "Sanitized as richtext from #{value.inspect} to #{sanitized_value.inspect}")
          end
        end

        def sanitize_attribute_as_string(attribute:, value:)
          sanitized_value = Loofah.fragment(value).text(encode_special_chars: false)

          if value != sanitized_value
            @record.send("#{attribute}=", sanitized_value)
            log(attribute:, message: "Sanitized as string from #{value.inspect} to #{sanitized_value.inspect}")
          end
        end

        def sanitize_attribute_via_proc(attribute:, value:, proc:)
          sanitized_value = proc.call(value)

          if value != sanitized_value
            @record.send("#{attribute}=", sanitized_value)
            log(attribute:, message: "Sanitized via proc from #{value.inspect} to #{sanitized_value.inspect}")
          end
        end

        def sanitize_atom
          if @record.changed_attributes.key?("data")
            @record.class::STRUCTURE.each do |attribute, type|
              sanitize_attribute(attribute: attribute.to_sym)
            end
          end
        end

        def sanitize_record
          @record.changed_attributes.each do |attribute, _change|
            sanitize_attribute(attribute: attribute.to_sym)
          end
        end

        def log(attribute:, message:)
          Rails.logger.debug("[Folio::HtmlSanitization::Sanitizer][#{@record.class}][#{@record.id || "new-record"}][#{attribute}] - #{message}")
        end
    end
  end
end
