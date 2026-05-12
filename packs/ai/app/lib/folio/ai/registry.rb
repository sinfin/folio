# frozen_string_literal: true

class Folio::Ai::Registry
  class Integration
    attr_reader :key,
                :record_class_name,
                :fields,
                :metadata

    def initialize(key:, record_class_name:, label: nil, fields:, metadata:)
      @key = key
      @record_class_name = record_class_name
      @label = label.presence
      @fields = fields
      @metadata = metadata
    end

    def label
      @label.presence || record_class.model_name.human(count: 2)
    end

    def record_class
      record_class_name.safe_constantize ||
        raise(ArgumentError, "AI integration record_class_name #{record_class_name} is unavailable")
    end
  end

  def initialize
    @integrations = {}
  end

  def register_integration(key: nil, record_class_name:, label: nil, fields: [], **metadata)
    klass = normalize_record_class(record_class_name)
    normalized_key = normalize_key(key.nil? ? klass.table_name : key)

    raise ArgumentError, "AI integration key is blank" if normalized_key.blank?
    raise ArgumentError, "AI integration #{normalized_key} is already registered" if integrations.key?(normalized_key)

    integrations[normalized_key] = Integration.new(key: normalized_key,
                                                   record_class_name: klass.name,
                                                   label:,
                                                   fields: normalize_fields(fields),
                                                   metadata:)
  end

  def integration(key)
    integrations[normalize_key(key)]
  end

  def field(integration_key, field_key)
    integration(integration_key)&.fields&.[](normalize_key(field_key))
  end

  def field_registered?(integration_key, field_key)
    field(integration_key, field_key).present?
  end

  def integrations_for_select
    integrations.values
  end

  private
    attr_reader :integrations

    def normalize_fields(fields)
      Array(fields).each_with_object({}) do |field_config, hash|
        field = normalize_field(field_config)

        raise ArgumentError, "AI field key is blank" if field.key.blank?
        raise ArgumentError, "AI field #{field.key} is registered twice" if hash.key?(field.key)

        hash[field.key] = field
      end
    end

    def normalize_field(field_config)
      case field_config
      when Folio::Ai::Field
        field_config
      when Hash
        Folio::Ai::Field.new(**field_config.symbolize_keys)
      else
        Folio::Ai::Field.new(key: field_config)
      end
    end

    def normalize_key(key)
      key.to_s.strip
    end

    def normalize_record_class(record_class_name)
      normalized_name = normalize_key(record_class_name)
      raise ArgumentError, "AI integration record_class_name is blank" if normalized_name.blank?

      klass = normalized_name.safe_constantize
      return klass if klass && klass < ActiveRecord::Base

      raise ArgumentError, "AI integration record_class_name must be an ActiveRecord::Base subclass"
    end
end
