# frozen_string_literal: true

class Folio::Ai::TextSuggestionRequest
  CURRENT_FORM_SNAPSHOT_FIELD_LIMIT = 200

  attr_reader :params

  def initialize(params:,
                 current_user:,
                 current_site:,
                 current_ability:,
                 raw_current_form_snapshot: nil)
    @params = params.to_h.with_indifferent_access
    @current_user = current_user
    @current_site = current_site
    @current_ability = current_ability
    @raw_current_form_snapshot = raw_current_form_snapshot
  end

  def component(result:, loading: false, loading_suggestion_count: nil, show_close: true, show_instructions: true)
    Folio::Ai::Console::TextSuggestionsComponent.new(result:,
                                                     component_id: component_id,
                                                     field_label: field_label,
                                                     integration_key: integration_key,
                                                     field_key: field_key,
                                                     show_meta: show_meta?,
                                                     loading:,
                                                     loading_suggestion_count: loading_suggestion_count || Folio::Ai::Console::TextSuggestionsComponent::LOADING_SUGGESTION_COUNT,
                                                     show_close:,
                                                     show_instructions:)
  end

  def loading_result(instructions: nil)
    result(success: true,
           user_instruction: effective_instruction(instructions))
  end

  def error_result(error_code, instructions: nil)
    result(success: false,
           error_code:,
           user_instruction: effective_instruction(instructions))
  end

  def immediate_error_code
    return :record_not_ready unless record
    :host_ineligible unless host_eligible?
  end

  def job_params(instructions:)
    {
      integration_key:,
      field_key:,
      component_id:,
      field_label:,
      show_meta: params[:show_meta],
      suggestion_count: params[:suggestion_count],
      instructions:,
      context: ai_context,
      host_eligible: host_eligible?,
      provider_adapter_class_name:,
    }.compact
  end

  def output_field_params
    {
      integration_key:,
      field_key:,
      component_id:,
      field_label:,
      show_meta: params[:show_meta],
    }.compact
  end

  def persist_instruction!(instructions)
    Folio::Ai::UserInstruction.upsert_instruction!(user: current_user,
                                                   site: ai_site,
                                                   integration_key:,
                                                   field_key:,
                                                   instruction: instructions.to_s)
                               .instruction
  end

  def effective_instruction(instructions)
    instructions.nil? ? stored_instruction : instructions.to_s
  end

  def tracking_payload
    {
      site_id: ai_site&.id,
      user_id: current_user&.id,
      integration_key:,
      field_key:,
      record_class: record_class&.name,
    }.compact
  end

  def integration_key
    params[:integration_key].to_s
  end

  def field_key
    params[:field_key].to_s
  end

  def component_id
    params[:component_id].presence || "folio_ai_text_suggestions"
  end

  def field_label
    registry_field&.label(record_class:) || field_key.humanize
  end

  def registry_field
    Folio::Ai.registry.field(integration_key, field_key)
  end

  def ai_site
    record_site || current_site
  end

  private
    attr_reader :current_user,
                :current_site,
                :current_ability,
                :raw_current_form_snapshot

    def result(success:, error_code: nil, user_instruction: nil)
      Folio::Ai::SuggestionGenerator::Result.new(success:,
                                                 suggestions: [],
                                                 error_code:,
                                                 field: registry_field,
                                                 user_instruction:,
                                                 warnings: [])
    end

    def record
      return @record if defined?(@record)

      @record = record_scope&.find_by(id: params[:id]) if requested_record_class_matches_integration?
      @record = nil if @record && !record_site_allowed?
      @record
    end

    def record_scope
      return unless record_class

      scope = record_class.accessible_by(current_ability)

      if !record_class.try(:console_api_autocomplete_dont_filter_by_site) && scope.respond_to?(:by_site)
        scope = scope.by_site(current_site)
      end

      scope
    end

    def record_class
      return @record_class if defined?(@record_class)

      @record_class = registry_integration&.record_class
    rescue ArgumentError
      @record_class = nil
    end

    def registry_integration
      @registry_integration ||= Folio::Ai.registry.integration(integration_key)
    end

    def requested_record_class_matches_integration?
      return true if params[:klass].blank?
      return false unless record_class

      requested_record_class.present? && requested_record_class <= record_class
    end

    def requested_record_class
      klass = params[:klass].to_s.safe_constantize
      klass if klass && klass < ActiveRecord::Base
    end

    def record_site_allowed?
      site = record_site
      site.blank? || site == current_site
    end

    def record_site
      if record.respond_to?(:folio_ai_site)
        record.folio_ai_site
      elsif record.respond_to?(:site)
        record.site
      end
    end

    def ai_context
      if record.respond_to?(:folio_ai_context)
        record.folio_ai_context(field_key:,
                                current_form_snapshot:)
      else
        { current_form_snapshot: }
      end
    end

    def host_eligible?
      return @host_eligible if defined?(@host_eligible)

      @host_eligible = if !record&.persisted?
        false
      elsif record.respond_to?(:folio_ai_suggestions_eligible?)
        record.folio_ai_suggestions_eligible?(field_key:,
                                              current_form_snapshot:)
      else
        true
      end
    end

    def provider_adapter_class_name
      return unless record.respond_to?(:folio_ai_provider_adapter)

      record.folio_ai_provider_adapter&.class&.name
    end

    def stored_instruction
      return "" if current_user.blank? || ai_site.blank?

      Folio::Ai::UserInstruction.find_or_initialize_for(user: current_user,
                                                        site: ai_site,
                                                        integration_key:,
                                                        field_key:).instruction.to_s
    end

    def current_form_snapshot
      @current_form_snapshot ||= Folio::Ai::CurrentFormSnapshot.call(snapshot: raw_current_form_snapshot,
                                                                     record_class:,
                                                                     limit: CURRENT_FORM_SNAPSHOT_FIELD_LIMIT)
    end

    def show_meta?
      ActiveModel::Type::Boolean.new.cast(params[:show_meta])
    end
end
