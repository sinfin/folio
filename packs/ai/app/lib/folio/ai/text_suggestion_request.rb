# frozen_string_literal: true

# Resolves one console AI suggestion request into record, site, field, provider,
# form snapshot, instructions, and job parameters.

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

  def group?
    ActiveModel::Type::Boolean.new.cast(params[:group])
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
    return if record_key.blank? || key.blank?

    Folio::Ai.registry.field(record_key, key)
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
    @form_snapshot ||= parsed_form_snapshot
  end

  def instructions
    return params[:instructions].to_s if params.key?(:instructions)

    stored_instruction
  end

  def persist_instructions!
    return instructions if current_user.blank? || site.blank?

    Folio::Ai::UserInstruction.upsert_instruction!(user: current_user,
                                                   site:,
                                                   record_key:,
                                                   field_key: key,
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
      group: group?,
      message_bus_client_id:,
      component_id:,
      form_snapshot:,
      instructions:,
      suggestion_count: suggestion_count,
      record_key:,
      field:,
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
    return :field_not_registered unless field
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
      snapshot = params[:current_form_snapshot]
      return normalize_snapshot(snapshot) if snapshot.present?

      JSON.parse(params[:current_form_snapshot_json].to_s)
    rescue JSON::ParserError
      {}
    end

    def normalize_snapshot(snapshot)
      snapshot = snapshot.to_unsafe_h if snapshot.respond_to?(:to_unsafe_h)
      snapshot.respond_to?(:to_h) ? snapshot.to_h : {}
    end

    def stored_instruction
      return "" if current_user.blank? || site.blank? || record_key.blank? || key.blank?

      Folio::Ai::UserInstruction.find_or_initialize_for(user: current_user,
                                                        site:,
                                                        record_key:,
                                                        field_key: key).instruction.to_s
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
      count.positive? ? count : Folio::Ai::TextSuggestionGenerator::DEFAULT_SUGGESTION_COUNT
    end

    def generator
      Folio::Ai::TextSuggestionGenerator.new(record:,
                                             site:,
                                             record_key:,
                                             field:,
                                             form_snapshot:,
                                             provider:,
                                             user_instruction: instructions,
                                             suggestion_count:)
    end
end
