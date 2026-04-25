# frozen_string_literal: true

class Folio::Ai::Registry
  Integration = Struct.new(:key, :label, :fields, :metadata, keyword_init: true)

  def initialize
    @integrations = {}
  end

  def register_integration(key, label: nil, fields: [], **metadata)
    normalized_key = normalize_key(key)

    raise ArgumentError, "AI integration key is blank" if normalized_key.blank?
    raise ArgumentError, "AI integration #{normalized_key} is already registered" if integrations.key?(normalized_key)

    integrations[normalized_key] = Integration.new(key: normalized_key,
                                                   label: label.presence || normalized_key.humanize,
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
end
