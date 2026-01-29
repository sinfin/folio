# frozen_string_literal: true

module Folio
  module Mcp
    module Tools
      class ApplyTranslations < Base
        class << self
          def call(original_tiptap:, translations:, structure_hash: nil, server_context:)
            return error_response("No original tiptap content provided") if original_tiptap.blank?
            return error_response("No translations provided") if translations.blank?

            # Optionally verify structure hasn't changed
            if structure_hash.present?
              current_hash = Digest::SHA256.hexdigest(original_tiptap.to_json)[0..15]
              if current_hash != structure_hash
                return error_response("Structure has changed since extraction. Please re-extract texts.")
              end
            end

            # Deep clone the original
            translated_tiptap = deep_clone(original_tiptap)

            # Apply translations
            translations_applied = 0
            translations.each do |translation|
              path = translation["path"] || translation[:path]
              value = translation["value"] || translation[:value]

              if apply_at_path(translated_tiptap, path, value)
                translations_applied += 1
              end
            end

            # Audit
            audit_log(server_context, {
              action: "apply_translations",
              translations_provided: translations.size,
              translations_applied: translations_applied
            })

            success_response({
              tiptap: translated_tiptap,
              translations_applied: translations_applied
            })
          rescue StandardError => e
            error_response("Error applying translations: #{e.message}")
          end

          private
            def deep_clone(obj)
              JSON.parse(obj.to_json)
            end

            def apply_at_path(obj, path, value)
              return false if path.blank?

              keys = path.split(".")
              target = obj

              # Navigate to parent
              keys[0..-2].each do |key|
                if target.is_a?(Array)
                  index = key.to_i
                  target = target[index]
                elsif target.is_a?(Hash)
                  target = target[key] || target[key.to_sym]
                else
                  return false
                end
                return false if target.nil?
              end

              # Set the value
              last_key = keys.last
              if target.is_a?(Array)
                target[last_key.to_i] = value
              elsif target.is_a?(Hash)
                # Try both string and symbol keys
                if target.key?(last_key)
                  target[last_key] = value
                elsif target.key?(last_key.to_sym)
                  target[last_key.to_sym] = value
                else
                  target[last_key] = value
                end
              else
                return false
              end

              true
            end
        end
      end
    end
  end
end
