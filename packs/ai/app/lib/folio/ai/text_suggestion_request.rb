# frozen_string_literal: true

# Resolves one console AI suggestion request into record, site, prompt,
# instructions, provider, form snapshot, and job parameters.

class Folio::Ai::TextSuggestionRequest
  attr_reader :params

  def initialize(params:, current_user:, current_site:, current_ability:)
    @params = params.to_h.with_indifferent_access
    @current_user = current_user
    @current_site = current_site
    @current_ability = current_ability
  end

  def key
    params[:key].to_s.strip
  end

  def grouped?
    ActiveModel::Type::Boolean.new.cast(params[:grouped])
  end

  def message_bus_client_id
    params[:message_bus_client_id].to_s.strip.presence
  end

  def component_id
    params[:component_id].to_s.strip.presence || "folio_ai_#{key}"
  end

  def record_key
    record_class&.table_name.to_s
  end

  def field
    return primary_field if grouped?
    return if record_key.blank? || key.blank?

    field_with_component_id(Folio::Ai.registry.field(record_key, key),
                            component_id)
  end

  def group
    return unless grouped? && record_key.present? && key.present?

    Folio::Ai.registry.group(record_key, key)
  end

  def fields
    return [field_with_component_id(field, component_id)].compact unless grouped?

    grouped_fields
  end

  def record
    return @record if defined?(@record)

    @record = find_record
    @record = nil if @record && !record_site_allowed?
    @record
  end

  def site
    record_site || current_site
  end

  def form_snapshot
    @form_snapshot ||= Folio::Ai::FormSnapshotSanitizer.call(record:,
                                                             snapshot: parsed_form_snapshot)
  end

  def instructions
    return params[:instructions].to_s if params.key?(:instructions)

    stored_instruction.to_s
  end

  def site_prompt
    return unless site.respond_to?(:ai_prompt_for)

    site.ai_prompt_for(record_key:,
                       key:,
                       grouped: grouped?)
  end

  def persist_instructions!
    return instructions if current_user.blank? || site.blank?

    Folio::Ai::UserInstruction.upsert_instruction!(user: current_user,
                                                   site:,
                                                   record_key:,
                                                   key:,
                                                   instruction: instructions).instruction
  end

  def provider
    Folio::Ai.provider_for(key: site_provider, model: site_model)
  end

  def suggestions
    generator.call
  end

  def job_params
    {
      klass: record_class&.name,
      id: record&.id,
      key:,
      grouped: grouped?,
      message_bus_client_id:,
      component_id:,
      form_snapshot:,
      site_prompt:,
      instructions:,
      suggestion_count: suggestion_count,
      record_key:,
      field: primary_field,
      fields:,
      site_id: site&.id,
      user_id: current_user&.id,
    }.compact
  end

  def ready?
    error_code.blank?
  end

  def error_code
    return :disabled unless Folio::Ai.config.enabled?
    return :missing_message_bus_client_id if message_bus_client_id.blank?
    return :missing_key if key.blank?
    return :record_not_found unless record
    return :site_disabled unless site_ai_enabled?
    return :field_not_registered unless registered_key?
    return :prompt_not_configured unless site_prompt_enabled?
    return :missing_context unless content_requirement_satisfied?
    :provider_unavailable unless provider_available?
  end

  private
    attr_reader :current_user,
                :current_site,
                :current_ability

    def record_class
      return @record_class if defined?(@record_class)

      klass = params[:klass].to_s.safe_constantize
      @record_class = klass if klass && klass < ActiveRecord::Base
    end

    def find_record
      return unless record_class && params[:id].present?

      record_scope.find_by(id: params[:id])
    end

    def record_scope
      scope = record_class.all
      current_ability ? scope.accessible_by(current_ability) : scope
    end

    def record_site
      record.site if record&.respond_to?(:site)
    end

    def record_site_allowed?
      record_site.blank? || current_site.blank? || record_site == current_site
    end

    def site_ai_enabled?
      !site.respond_to?(:ai_enabled?) || site.ai_enabled?
    end

    def parsed_form_snapshot
      return @parsed_form_snapshot if defined?(@parsed_form_snapshot)

      snapshot = params[:current_form_snapshot]
      if snapshot.present?
        @parsed_form_snapshot = normalize_snapshot(snapshot)
        return @parsed_form_snapshot
      end

      @parsed_form_snapshot = JSON.parse(params[:current_form_snapshot_json].to_s)
    rescue JSON::ParserError
      @parsed_form_snapshot = {}
    end

    def normalize_snapshot(snapshot)
      snapshot = snapshot.to_unsafe_h if snapshot.respond_to?(:to_unsafe_h)
      snapshot.respond_to?(:to_h) ? snapshot.to_h : {}
    end

    def stored_instruction
      return if current_user.blank? || site.blank? || record_key.blank? || key.blank?

      Folio::Ai::UserInstruction.find_or_initialize_for(user: current_user,
                                                        site:,
                                                        record_key:,
                                                        key:).instruction
    end

    def site_prompt_enabled?
      site.respond_to?(:ai_prompt_enabled_for?) &&
        site.ai_prompt_enabled_for?(record_key:,
                                    key:,
                                    grouped: grouped?)
    end

    def content_requirement_satisfied?
      Folio::Ai::ContentRequirement.satisfied?(record:,
                                               requirement: record_config&.dig(:content_requirement),
                                               form_snapshot:)
    end

    def site_provider
      site&.respond_to?(:ai_provider) ? site.ai_provider : Folio::Ai.config.default_provider
    end

    def site_model
      site&.respond_to?(:ai_model) ? site.ai_model : Folio::Ai.config.default_model(site_provider)
    end

    def provider_available?
      provider
      true
    rescue Folio::Ai::ProviderError, ArgumentError, KeyError
      false
    end

    def suggestion_count
      count = params[:suggestion_count].to_i
      count.positive? ? count : Folio::Ai::DEFAULT_SUGGESTION_COUNT
    end

    def grouped_fields
      return [] unless group

      component_ids = grouped_component_ids

      group.fetch(:fields).filter_map do |field_key|
        registered_field = Folio::Ai.registry.field(record_key, field_key)
        next unless registered_field

        field_with_component_id(registered_field,
                                component_ids[field_key].presence || "folio_ai_#{field_key}")
      end
    end

    def grouped_component_ids
      raw_fields.each_with_object({}) do |field_config, hash|
        field_hash = hash_from(field_config)
        field_key = field_hash["key"].to_s.strip
        hash[field_key] = field_hash["component_id"].to_s.strip if field_key.present?
      end
    end

    def raw_fields
      value = params[:fields]
      value = JSON.parse(value) if value.is_a?(String)
      Array(value)
    rescue JSON::ParserError
      []
    end

    def hash_from(value)
      value = value.to_unsafe_h if value.respond_to?(:to_unsafe_h)
      value.respond_to?(:to_h) ? value.to_h.with_indifferent_access : {}
    end

    def field_with_component_id(registered_field, component_id)
      return unless registered_field

      registered_field.merge(label: field_label(registered_field),
                             component_id:)
    end

    def field_label(field)
      field[:label].presence ||
        record_class.human_attribute_name(field.fetch(:key)) ||
        field.fetch(:key).humanize
    end

    def primary_field
      fields.first
    end

    def registered_key?
      grouped? ? group.present? && fields.present? : field.present?
    end

    def record_config
      @record_config ||= Folio::Ai.registry.record(record_key)
    end

    def generator
      Folio::Ai::TextSuggestionGenerator.new(record:,
                                             site:,
                                             record_key:,
                                             field:,
                                             form_snapshot:,
                                             provider:,
                                             site_prompt:,
                                             instructions:,
                                             suggestion_count:)
    end
end
