# frozen_string_literal: true

class Folio::Ai::BatchTextSuggestionsJob < Folio::ApplicationJob
  queue_as { Folio::Ai.config.text_suggestions_queue }

  def perform(request_id:, message_bus_client_id:, user_id:, site_id:, params:)
    @request_id = request_id
    @message_bus_client_id = message_bus_client_id
    @params = params
    @user = Folio::User.find_by(id: user_id)
    @site = Folio::Site.find_by(id: site_id)

    return unless valid_delivery?

    I18n.with_locale(site.console_locale) do
      broadcast_result(suggestion_result)
    end
  rescue StandardError => e
    log_failure(e)
    broadcast_result(error_batch_result(:provider_error)) if can_broadcast_failure?
  end

  private
    attr_reader :request_id,
                :message_bus_client_id,
                :user,
                :site

    def valid_delivery?
      request_id.present? && message_bus_client_id.present? && user.present? && site.present?
    end

    def can_broadcast_failure?
      request_id.present? && message_bus_client_id.present?
    end

    def log_failure(error)
      Rails.logger.warn(
        "[Folio::Ai] Batch text suggestions job failed: " \
        "error_class=#{error.class.name} " \
        "request_id=#{request_id} " \
        "integration_key=#{request_params[:integration_key]} " \
        "field_key=#{request_params[:field_key]}"
      )
    end

    def suggestion_result
      Folio::Ai::BatchSuggestionGenerator.new(site:,
                                              user:,
                                              integration_key: request_params[:integration_key],
                                              field_key: request_params[:field_key],
                                              fields: output_field_params,
                                              context: request_params[:context],
                                              instructions: request_params[:instructions],
                                              provider_adapter_class_name: request_params[:provider_adapter_class_name]).call
    end

    def error_batch_result(error_code)
      Folio::Ai::BatchSuggestionGenerator::Result.new(results: output_field_params.each_with_object({}) do |field_params, hash|
        hash[component_id(field_params)] = error_result(error_code, field_params:)
      end)
    end

    def error_result(error_code, field_params:)
      Folio::Ai::SuggestionGenerator::Result.new(success: false,
                                                 suggestions: [],
                                                 error_code:,
                                                 field: registry_field(field_params),
                                                 user_instruction: stored_instruction,
                                                 warnings: [])
    end

    def stored_instruction
      return "" if user.blank? || site.blank?

      Folio::Ai::UserInstruction.find_or_initialize_for(user:,
                                                        site:,
                                                        integration_key: request_params[:integration_key],
                                                        field_key: request_params[:field_key]).instruction.to_s
    end

    def request_params
      @request_params ||= (@params || {}).to_h.with_indifferent_access
    end

    def output_field_params
      @output_field_params ||= Array(request_params[:fields]).map { |field| field.to_h.with_indifferent_access }
    end

    def broadcast_result(result)
      MessageBus.publish Folio::MESSAGE_BUS_CHANNEL,
                         {
                           type: self.class.name,
                           data: {
                             request_id:,
                             integration_key: request_params[:integration_key],
                             field_key: request_params[:field_key],
                             panels: rendered_panels(result:),
                           },
                         }.to_json,
                         client_ids: [message_bus_client_id]
    end

    def rendered_panels(result:)
      output_field_params.each_with_object({}) do |field_params, hash|
        component_id = component_id(field_params)

        hash[component_id] = Folio::ApplicationController.renderer.render(
          text_suggestions_component(field_params:,
                                     result: result.results[component_id] || error_result(:provider_error,
                                                                                          field_params:)),
          layout: false
        )
      end
    end

    def text_suggestions_component(field_params:, result:)
      Folio::Ai::Console::TextSuggestionsComponent.new(result:,
                                                       component_id: component_id(field_params),
                                                       field_label: field_label(field_params),
                                                       integration_key: field_params[:integration_key],
                                                       field_key: field_params[:field_key],
                                                       show_meta: show_meta?(field_params),
                                                       show_close: false,
                                                       show_instructions: false)
    end

    def registry_field(field_params)
      Folio::Ai.registry.field(field_params[:integration_key], field_params[:field_key])
    end

    def field_label(field_params)
      field_params[:field_label].presence || registry_field(field_params)&.label || field_params[:field_key].to_s.humanize
    end

    def component_id(field_params)
      field_params[:component_id].presence || "folio_ai_text_suggestions"
    end

    def show_meta?(field_params)
      ActiveModel::Type::Boolean.new.cast(field_params[:show_meta])
    end
end
