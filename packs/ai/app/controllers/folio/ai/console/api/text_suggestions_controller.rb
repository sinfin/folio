# frozen_string_literal: true

class Folio::Ai::Console::Api::TextSuggestionsController < Folio::Console::Api::BaseController
  CURRENT_FORM_SNAPSHOT_FIELD_LIMIT = 200

  def text_suggestions
    render_text_suggestions(instructions: nil, persist_instructions: false)
  end

  def instructions
    render_text_suggestions(instructions: ai_params[:instructions], persist_instructions: true)
  end

  private
    def render_text_suggestions(instructions:, persist_instructions:)
      return render_missing_message_bus_client_id if message_bus_client_id.blank?

      effective_instructions = if persist_instructions && record
        persist_user_instruction(instructions)
      elsif persist_instructions
        instructions.to_s
      else
        instructions
      end

      if (error_code = immediate_error_code)
        return render_component_json(text_suggestions_component(result: error_result(error_code,
                                                                                     instructions: effective_instructions)))
      end

      request_id = SecureRandom.urlsafe_base64(18)

      Folio::Ai::TextSuggestionsJob.perform_later(request_id:,
                                                  message_bus_client_id:,
                                                  user_id: Folio::Current.user.id,
                                                  site_id: ai_site.id,
                                                  params: job_params(instructions: effective_instructions))

      render_component_json(text_suggestions_component(result: loading_result(instructions: effective_instructions),
                                                       loading: true),
                            meta: { request_id: })
    end

    def text_suggestions_component(result:, loading: false)
      Folio::Ai::Console::TextSuggestionsComponent.new(result:,
                                                       component_id: component_id,
                                                       field_label: field_label,
                                                       integration_key: ai_params[:integration_key],
                                                       field_key: ai_params[:field_key],
                                                       show_meta: show_meta?,
                                                       loading:)
    end

    def loading_result(instructions:)
      Folio::Ai::SuggestionGenerator::Result.new(success: true,
                                                 suggestions: [],
                                                 field: registry_field,
                                                 user_instruction: loading_instruction(instructions),
                                                 warnings: [])
    end

    def error_result(error_code, instructions:)
      Folio::Ai::SuggestionGenerator::Result.new(success: false,
                                                 suggestions: [],
                                                 error_code:,
                                                 field: registry_field,
                                                 user_instruction: loading_instruction(instructions),
                                                 warnings: [])
    end

    def immediate_error_code
      return :record_not_ready unless record
      :host_ineligible unless host_eligible?
    end

    def loading_instruction(instructions)
      instructions.nil? ? stored_instruction : instructions.to_s
    end

    def persist_user_instruction(instructions)
      Folio::Ai::UserInstruction.upsert_instruction!(user: Folio::Current.user,
                                                     site: ai_site,
                                                     integration_key: ai_params[:integration_key],
                                                     field_key: ai_params[:field_key],
                                                     instruction: instructions.to_s)
                                 .instruction
                                 .tap do
        Folio::Ai.track(:user_instruction_saved, tracking_payload)
      end
    end

    def tracking_payload
      {
        site_id: ai_site&.id,
        user_id: Folio::Current.user&.id,
        integration_key: ai_params[:integration_key].to_s,
        field_key: ai_params[:field_key].to_s,
        record_class: record_class&.name,
      }.compact
    end

    def render_missing_message_bus_client_id
      render json: {
        errors: [
          {
            title: "message_bus_client_id is required",
          },
        ],
      }, status: :unprocessable_entity
    end

    def job_params(instructions:)
      params = {
        integration_key: ai_params[:integration_key],
        field_key: ai_params[:field_key],
        component_id: component_id,
        field_label: field_label,
        show_meta: ai_params[:show_meta],
        suggestion_count: ai_params[:suggestion_count],
        instructions:,
      }

      return params.merge(error_code: :record_not_ready).compact unless record

      eligible = host_eligible?

      params.merge(context: eligible ? ai_context : {},
                   host_eligible: eligible,
                   provider_adapter_class_name: provider_adapter_class_name).compact
    end

    def record
      return @record if defined?(@record)

      @record = if requested_record_class_matches_integration?
        record_scope&.find_by(id: ai_params[:id])
      end
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

      @record_class = registry_integration&.record_class
    rescue ArgumentError
      @record_class = nil
    end

    def registry_integration
      @registry_integration ||= Folio::Ai.registry.integration(ai_params[:integration_key])
    end

    def requested_record_class_matches_integration?
      return true if ai_params[:klass].blank?
      return false unless record_class

      requested_record_class.present? && requested_record_class <= record_class
    end

    def requested_record_class
      return @requested_record_class if defined?(@requested_record_class)

      klass = ai_params[:klass].to_s.safe_constantize
      @requested_record_class = klass if klass && klass < ActiveRecord::Base
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
      if record.respond_to?(:folio_ai_context)
        record.folio_ai_context(field_key: ai_params[:field_key].to_s,
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
        record.folio_ai_suggestions_eligible?(field_key: ai_params[:field_key].to_s,
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
      registry_field&.label(record_class:) || ai_params[:field_key].to_s.humanize
    end

    def component_id
      ai_params[:component_id].presence || "folio_ai_text_suggestions"
    end

    def show_meta?
      ActiveModel::Type::Boolean.new.cast(ai_params[:show_meta])
    end

    def current_form_snapshot
      @current_form_snapshot ||= sanitize_current_form_snapshot(raw_current_form_snapshot)
    end

    def message_bus_client_id
      ai_params[:message_bus_client_id].presence
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
                    :show_meta,
                    :suggestion_count,
                    :instructions,
                    :message_bus_client_id,
                    :current_form_snapshot_json,
                    current_form_snapshot: {})
    end
end
