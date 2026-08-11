# frozen_string_literal: true

# Stores record, field, and group metadata used by AI-enabled form inputs.
class Folio::Ai::Registry
  CONTENT_REQUIREMENTS = [
    :tiptap_or_atoms,
  ].freeze

  def initialize
    @records = {}
  end

  def register_record(record_class_name:, fields:, groups: [], content_requirement: nil)
    record_class = resolve_record_class(record_class_name)
    key = record_class.table_name
    raise ArgumentError, "AI record already registered: #{key}" if @records.key?(key)

    normalized_fields = normalize_fields(fields, record_class:)

    @records[key] = {
      key:,
      record_class_name: record_class.name,
      content_requirement: normalize_content_requirement(content_requirement),
      fields: normalized_fields,
      groups: normalize_groups(groups, fields: normalized_fields),
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

  def group(record_key, group_key)
    record(record_key)&.dig(:groups, group_key.to_s)
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
        label: attributes[:label].presence,
        character_limit: attributes[:character_limit],
      }
    end

    def normalize_groups(groups, fields:)
      Array(groups).each_with_object({}) do |group_config, hash|
        group = normalize_group(group_config, fields:)
        raise ArgumentError, "AI group already registered: #{group[:key]}" if hash.key?(group[:key])

        hash[group[:key]] = group
      end
    end

    def normalize_group(group_config, fields:)
      attributes = case group_config
                   when Hash
                     group_config.symbolize_keys
                   else
                     { key: group_config }
      end

      key = normalize_key(attributes[:key])
      raise ArgumentError, "AI group key cannot match field key: #{key}" if fields.key?(key)

      field_keys = Array(attributes[:fields]).map { |field_key| normalize_key(field_key) }
      raise ArgumentError, "AI group fields cannot be blank" if field_keys.blank?

      missing_field_keys = field_keys.reject { |field_key| fields.key?(field_key) }
      raise ArgumentError, "AI group fields are not registered: #{missing_field_keys.join(', ')}" if missing_field_keys.present?

      {
        key:,
        label: attributes[:label].presence,
        fields: field_keys,
      }
    end

    def normalize_content_requirement(value)
      return if value.blank?

      requirement = value.to_sym
      return requirement if CONTENT_REQUIREMENTS.include?(requirement)

      raise ArgumentError, "AI content requirement is not supported: #{value}"
    end

    def normalize_key(value)
      value.to_s.strip.presence || raise(ArgumentError, "AI field key cannot be blank")
    end
end
