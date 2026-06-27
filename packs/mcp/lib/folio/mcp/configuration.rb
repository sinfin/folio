# frozen_string_literal: true

module Folio
  module Mcp
    class Configuration
      attr_accessor :resources, :locales, :audit_logger, :rate_limit

      def initialize
        @resources = {}
        @locales = [:en]
        @rate_limit = 100 # requests per minute
        @audit_logger = nil
      end

      def resource(name, &block)
        config = ResourceConfig.new
        config.instance_eval(&block) if block_given?
        @resources[name.to_sym] = config.to_h
      end
    end

    class ResourceConfig
      def initialize
        @model = nil
        @fields = []
        @tiptap_fields = []
        @allowed_types = []
        @cover_field = nil
        @searchable = false
        @uploadable = false
        @versioned = false
        @allowed_actions = %i[read create update destroy]
        @authorize_with = :console_ability
      end

      def model(value = nil)
        return @model if value.nil?

        @model = value
      end

      def allowed_types(value = nil)
        return @allowed_types if value.nil?

        @allowed_types = value
      end

      def fields(value = nil)
        return @fields if value.nil?

        @fields = value
      end

      def tiptap_fields(value = nil)
        return @tiptap_fields if value.nil?

        @tiptap_fields = value
      end

      def cover_field(value = nil)
        return @cover_field if value.nil?

        @cover_field = value
      end

      def searchable(value = nil)
        return @searchable if value.nil?

        @searchable = value
      end

      def uploadable(value = nil)
        return @uploadable if value.nil?

        @uploadable = value
      end

      def versioned(value = nil)
        return @versioned if value.nil?

        @versioned = value
      end

      def allowed_actions(value = nil)
        return @allowed_actions if value.nil?

        @allowed_actions = value
      end

      def authorize_with(value = nil)
        return @authorize_with if value.nil?

        @authorize_with = value
      end

      def to_h
        {
          model: @model,
          allowed_types: @allowed_types,
          fields: @fields,
          tiptap_fields: @tiptap_fields,
          cover_field: @cover_field,
          searchable: @searchable,
          uploadable: @uploadable,
          versioned: @versioned,
          allowed_actions: @allowed_actions,
          authorize_with: @authorize_with
        }
      end
    end
  end
end
