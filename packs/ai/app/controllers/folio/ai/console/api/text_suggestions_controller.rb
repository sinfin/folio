# frozen_string_literal: true

class Folio::Ai::Console::Api::TextSuggestionsController < Folio::Console::Api::BaseController
  CURRENT_FORM_SNAPSHOT_FIELD_LIMIT = 200
  MAX_SUGGESTION_COUNT = 10

  def show
    render_text_suggestions(instructions: nil, persist_instructions: false)
  end

  def instructions
    render_text_suggestions(instructions: ai_params[:instructions], persist_instructions: true)
  end

  private
    def render_text_suggestions(instructions:, persist_instructions:)
      render_component_json(text_suggestions_component(instructions:, persist_instructions:))
    end

    def text_suggestions_component(instructions:, persist_instructions:)
      Folio::Ai::Console::TextSuggestionsComponent.new(result: suggestion_result(instructions:,
                                                                                 persist_instructions:),
                                                       component_id: component_id,
                                                       field_label: field_label,
                                                       target_input_id: ai_params[:target_input_id],
                                                       integration_key: ai_params[:integration_key],
                                                       field_key: ai_params[:field_key],
                                                       show_meta: show_meta?)
    end

    def suggestion_result(instructions:, persist_instructions:)
      return error_result(:record_not_ready) unless record
      return error_result(:invalid_context) unless record.respond_to?(:folio_ai_context)

      Folio::Ai::SuggestionGenerator.new(site: ai_site,
                                         user: Folio::Current.user,
                                         integration_key: ai_params[:integration_key],
                                         field_key: ai_params[:field_key],
                                         context: -> { ai_context },
                                         instructions:,
                                         persist_instructions:,
                                         host_eligible: host_eligible?,
                                         suggestion_count: suggestion_count,
                                         provider_adapter: provider_adapter).call
    end

    def error_result(error_code)
      Folio::Ai::SuggestionGenerator::Result.new(success: false,
                                                 suggestions: [],
                                                 error_code:,
                                                 field: registry_field,
                                                 user_instruction: stored_instruction,
                                                 warnings: [])
    end

    def record
      return @record if defined?(@record)

      @record = record_scope&.find_by(id: ai_params[:id])
      @record = nil if @record && !record_site_allowed?
      @record
    end

    def record_scope
      return unless record_class

      scope = record_class.accessible_by(Folio::Current.ability)

      if !record_class.try(:console_api_autocomplete_dont_filter_by_site) && scope.respond_to?(:by_site)
        scope = scope.by_site(Folio::Current.site)
      end

      scope
    end

    def record_class
      return @record_class if defined?(@record_class)

      klass = ai_params[:klass].to_s.safe_constantize
      @record_class = klass if klass && klass < ActiveRecord::Base
    end

    def record_site_allowed?
      site = record_site
      site.blank? || site == Folio::Current.site
    end

    def ai_site
      record_site || Folio::Current.site
    end

    def record_site
      if record.respond_to?(:folio_ai_site)
        record.folio_ai_site
      elsif record.respond_to?(:site)
        record.site
      end
    end

    def ai_context
      record.folio_ai_context(field_key: ai_params[:field_key].to_s,
                              current_form_snapshot:)
    end

    def host_eligible?
      return false unless record&.persisted?
      return true unless record.respond_to?(:folio_ai_suggestions_eligible?)

      record.folio_ai_suggestions_eligible?(field_key: ai_params[:field_key].to_s,
                                            current_form_snapshot:)
    end

    def provider_adapter
      record.folio_ai_provider_adapter if record.respond_to?(:folio_ai_provider_adapter)
    end

    def stored_instruction
      return "" if Folio::Current.user.blank? || ai_site.blank?

      Folio::Ai::UserInstruction.find_or_initialize_for(user: Folio::Current.user,
                                                        site: ai_site,
                                                        integration_key: ai_params[:integration_key],
                                                        field_key: ai_params[:field_key]).instruction.to_s
    end

    def registry_field
      Folio::Ai.registry.field(ai_params[:integration_key], ai_params[:field_key])
    end

    def field_label
      registry_field&.label || ai_params[:field_key].to_s.humanize
    end

    def component_id
      ai_params[:component_id].presence || "folio_ai_text_suggestions"
    end

    def show_meta?
      ActiveModel::Type::Boolean.new.cast(ai_params[:show_meta])
    end

    def suggestion_count
      value = ai_params[:suggestion_count].to_i

      if value.positive?
        [value, MAX_SUGGESTION_COUNT].min
      else
        Folio::Ai::ResponseNormalizer::DEFAULT_SUGGESTION_COUNT
      end
    end

    def current_form_snapshot
      @current_form_snapshot ||= sanitize_current_form_snapshot(raw_current_form_snapshot)
    end

    def raw_current_form_snapshot
      snapshot = ai_params[:current_form_snapshot]
      return snapshot if snapshot.present?
      return if ai_params[:current_form_snapshot_json].blank?

      JSON.parse(ai_params[:current_form_snapshot_json])
    rescue JSON::ParserError
      {}
    end

    def sanitize_current_form_snapshot(snapshot)
      snapshot = snapshot.to_unsafe_h if snapshot.respond_to?(:to_unsafe_h)
      return {} unless snapshot.is_a?(Hash)

      snapshot.first(CURRENT_FORM_SNAPSHOT_FIELD_LIMIT).each_with_object({}) do |(key, value), sanitized|
        sanitized_value = sanitize_current_form_snapshot_value(value)
        sanitized[key.to_s] = sanitized_value unless sanitized_value.nil?
      end
    end

    def sanitize_current_form_snapshot_value(value)
      if value.is_a?(Array)
        value.filter_map { |item| sanitize_current_form_snapshot_scalar(item) }
      else
        sanitize_current_form_snapshot_scalar(value)
      end
    end

    def sanitize_current_form_snapshot_scalar(value)
      case value
      when String
        value
      when Numeric, TrueClass, FalseClass
        value.to_s
      end
    end

    def ai_params
      params.permit(:klass,
                    :id,
                    :integration_key,
                    :field_key,
                    :component_id,
                    :target_input_id,
                    :show_meta,
                    :suggestion_count,
                    :instructions,
                    :current_form_snapshot_json,
                    current_form_snapshot: {})
    end
end
