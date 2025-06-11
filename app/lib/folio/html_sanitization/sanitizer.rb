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
          return if !value.is_a?(String) && !value.is_a?(Hash)

          attribute_config = attributes_config[attribute] || DEFAULT_ATTRIBUTE_CONFIG

          if attribute_config.is_a?(Proc)
            sanitize_attribute_via_proc(attribute:, value:, proc: attribute_config)
          else
            case attribute_config
            when :unsafe_html
              # No sanitization for unsafe_html
            when :rich_text
              sanitize_attribute_as_rich_text(attribute:, value:)
            when :string
              sanitize_attribute_as_string(attribute:, value:)
            else
              raise ArgumentError, "Unknown attribute config: #{attribute_config.inspect}"
            end
          end
        end

        def handle_hash_or_string_attribute(attribute:, value:, sanitize_method:, logger_info:)
          changed = false
          sanitized_value = nil

          if value.is_a?(Hash)
            recursively_sanitize_hash_proc = -> (hash) do
              hash.transform_values do |hash_value|
                result = if hash_value.is_a?(String)
                  send(sanitize_method, value: hash_value)
                elsif hash_value.is_a?(Hash)
                  recursively_sanitize_hash_proc.call(hash_value)
                else
                  hash_value
                end

                changed ||= result != hash_value

                result
              end
            end

            sanitized_value = recursively_sanitize_hash_proc.call(value)
          else
            sanitized_value = send(sanitize_method, value:)
            changed = sanitized_value != value
          end

          if changed
            @record.send("#{attribute}=", sanitized_value)
            log(attribute:, message: "Sanitized as #{logger_info} from #{value.inspect} to #{sanitized_value.inspect}")
          end
        end

        def sanitize_value_as_rich_text(value:)
          ActionController::Base.helpers.sanitize(value)
        end

        def sanitize_attribute_as_rich_text(attribute:, value:)
          handle_hash_or_string_attribute(attribute:, value:, sanitize_method: :sanitize_value_as_rich_text, logger_info: :rich_text)
        end

        def sanitize_value_as_string(value:)
          Loofah.fragment(value).text(encode_special_chars: false)
        end

        def sanitize_attribute_as_string(attribute:, value:)
          handle_hash_or_string_attribute(attribute:, value:, sanitize_method: :sanitize_value_as_string, logger_info: :string)
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
