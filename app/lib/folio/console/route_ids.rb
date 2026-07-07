# frozen_string_literal: true

module Folio::Console::RouteIds
  module PolymorphicRoutes
    def polymorphic_url(record_or_hash_or_array, options = {})
      super(Folio::Console::RouteIds.normalize(record_or_hash_or_array), options)
    end

    def polymorphic_path(record_or_hash_or_array, options = {})
      super(Folio::Console::RouteIds.normalize(record_or_hash_or_array), options)
    end
  end

  class Record
    def initialize(record)
      @record = record.to_model
    end

    def to_model
      self
    end

    def persisted?
      true
    end

    def model_name
      @record.model_name
    end

    def to_key
      [@record.id]
    end

    def to_param
      @record.id.to_s
    end

    def method_missing(method_name, ...)
      if @record.respond_to?(method_name)
        @record.public_send(method_name, ...)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @record.respond_to?(method_name, include_private) || super
    end
  end

  class << self
    def install!
      return if ActionDispatch::Routing::PolymorphicRoutes < PolymorphicRoutes

      ActionDispatch::Routing::PolymorphicRoutes.prepend(PolymorphicRoutes)
    end

    def normalize(value)
      return value unless value.is_a?(Array)
      return value unless value.include?(:console)

      value.map { |item| normalize_item(item) }
    end

    private
      def normalize_item(item)
        return item unless route_record?(item)

        Record.new(item)
      end

      def route_record?(item)
        return false if item.is_a?(Class)
        return false unless item.respond_to?(:to_model)

        model = item.to_model
        model.respond_to?(:persisted?) && model.persisted?
      end
  end
end
