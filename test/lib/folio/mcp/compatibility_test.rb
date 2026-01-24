# frozen_string_literal: true

require "test_helper"

module Folio
  module Mcp
    class CompatibilityTest < ActiveSupport::TestCase
      test "all Tiptap nodes have valid structure" do
        skip "No Tiptap nodes defined" unless defined?(Folio::Tiptap::Node)

        errors = []

        Folio::Tiptap::Node.descendants.each do |klass|
          next if klass.name&.include?("Test")
          next unless klass.respond_to?(:structure)

          # Check structure fields have known types
          klass.structure.each do |field, type_def|
            type = extract_type(type_def)
            unless type.nil? || Folio::Mcp::KNOWN_FIELD_TYPES.include?(type)
              errors << "#{klass}: unknown field type '#{type}' for field '#{field}'"
            end
          end
        end

        assert errors.empty?, "MCP compatibility issues:\n#{errors.join("\n")}"
      end

      test "MCP schema can be generated without errors" do
        schema = Folio::Mcp::TiptapSchemaGenerator.new.generate

        assert schema[:nodes].is_a?(Hash), "Schema should have nodes hash"
        assert schema[:field_types].is_a?(Hash), "Schema should have field_types"
        assert schema[:groups].is_a?(Hash), "Schema should have groups"
      end

      test "all configured MCP resources have valid models" do
        Folio::Mcp.configure do |config|
          config.resources = {
            pages: {
              model: "Folio::Page",
              fields: %i[title slug],
              tiptap_fields: %i[tiptap_content]
            }
          }
        end

        Folio::Mcp.configuration.resources.each do |name, config|
          model_class = config[:model].safe_constantize

          assert model_class.present?,
                 "MCP resource '#{name}' has invalid model: #{config[:model]}"

          # Check tiptap_fields exist on model
          config[:tiptap_fields]&.each do |field|
            has_method = model_class.method_defined?(field) ||
                         model_class.column_names.include?(field.to_s) ||
                         model_class.instance_methods.include?(field)

            # Allow for dynamic methods that might not be defined at class level
            assert has_method || model_class.new.respond_to?(field),
                   "MCP resource '#{name}' model missing tiptap field: #{field}"
          end
        end
      ensure
        Folio::Mcp.reset_configuration!
      end

      private

      def extract_type(type_def)
        case type_def
        when Symbol
          type_def
        when Array
          :enum
        when Hash
          type_def[:type]
        end
      end
    end
  end
end
