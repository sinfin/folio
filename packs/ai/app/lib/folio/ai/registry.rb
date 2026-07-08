# frozen_string_literal: true

class Folio::Ai::Registry
  def initialize
    @records = {}
  end

  def register_record(record_class_name:, fields:)
    record_class = resolve_record_class(record_class_name)
    key = record_class.table_name
    raise ArgumentError, "AI record already registered: #{key}" if @records.key?(key)

    @records[key] = {
      key:,
      record_class_name: record_class.name,
      label: record_class.model_name.human(count: 2),
      fields: normalize_fields(fields, record_class:),
    }
  end

  def record(key)
    @records[key.to_s]
  end

  def records
    @records.values
  end

  def field(record_key, field_key)
    record(record_key)&.dig(:fields, field_key.to_s)
  end

  private
    def resolve_record_class(record_class_name)
      record_class = record_class_name.to_s.safe_constantize
      return record_class if record_class && record_class < ActiveRecord::Base

      raise ArgumentError, "AI record class must be an ActiveRecord model"
    end

    def normalize_fields(fields, record_class:)
      Array(fields).each_with_object({}) do |field_config, hash|
        field = normalize_field(field_config, record_class:)
        raise ArgumentError, "AI field already registered: #{field[:key]}" if hash.key?(field[:key])

        hash[field[:key]] = field
      end
    end

    def normalize_field(field_config, record_class:)
      attributes = case field_config
                   when Hash
                     field_config.symbolize_keys
                   else
                     { key: field_config }
      end

      key = normalize_key(attributes[:key])

      {
        key:,
        label: attributes[:label].presence || record_class.human_attribute_name(key),
        character_limit: attributes[:character_limit],
      }
    end

    def normalize_key(value)
      value.to_s.strip.presence || raise(ArgumentError, "AI field key cannot be blank")
    end
end
