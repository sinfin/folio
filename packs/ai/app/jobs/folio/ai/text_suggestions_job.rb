# frozen_string_literal: true

class Folio::Ai::TextSuggestionsJob < Folio::ApplicationJob
  MAX_SUGGESTION_COUNT = 10

  queue_as { Folio::Ai.text_suggestions_queue }

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
    Rails.logger.warn("[Folio::Ai] Text suggestions job failed: #{e.class}: #{e.message}")
    broadcast_result(error_result(:provider_error)) if can_broadcast_failure?
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

    def suggestion_result
      return error_result(precomputed_error_code) if precomputed_error_code

      Folio::Ai::SuggestionGenerator.new(site: site,
                                         user: user,
                                         integration_key: request_params[:integration_key],
                                         field_key: request_params[:field_key],
                                         context: request_params[:context] || {},
                                         instructions: request_params[:instructions],
                                         persist_instructions: false,
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

    def host_eligible?
      return true unless request_params.key?(:host_eligible)

      ActiveModel::Type::Boolean.new.cast(request_params[:host_eligible])
    end

    def provider_adapter
      provider_adapter_class_name = request_params[:provider_adapter_class_name].presence
      provider_adapter_class = provider_adapter_class_name&.safe_constantize

      provider_adapter_class&.new
    end

    def stored_instruction
      return "" if user.blank? || site.blank?

      Folio::Ai::UserInstruction.find_or_initialize_for(user:,
                                                        site: site,
                                                        integration_key: request_params[:integration_key],
                                                        field_key: request_params[:field_key]).instruction.to_s
    end

    def registry_field
      Folio::Ai.registry.field(request_params[:integration_key], request_params[:field_key])
    end

    def field_label
      request_params[:field_label].presence || registry_field&.label || request_params[:field_key].to_s.humanize
    end

    def component_id
      request_params[:component_id].presence || "folio_ai_text_suggestions"
    end

    def show_meta?
      ActiveModel::Type::Boolean.new.cast(request_params[:show_meta])
    end

    def suggestion_count
      value = request_params[:suggestion_count].to_i

      if value.positive?
        [value, MAX_SUGGESTION_COUNT].min
      else
        Folio::Ai::ResponseNormalizer::DEFAULT_SUGGESTION_COUNT
      end
    end

    def request_params
      @request_params ||= (@params || {}).to_h.with_indifferent_access
    end

    def precomputed_error_code
      request_params[:error_code]&.to_sym
    end

    def broadcast_result(result)
      MessageBus.publish Folio::MESSAGE_BUS_CHANNEL,
                         {
                           type: self.class.name,
                           data: {
                             request_id:,
                             component_id: component_id,
                             html: rendered_component_html(result:),
                           },
                         }.to_json,
                         client_ids: [message_bus_client_id]
    end

    def rendered_component_html(result:)
      Folio::ApplicationController.renderer.render(
        Folio::Ai::Console::TextSuggestionsComponent.new(result:,
                                                         component_id: component_id,
                                                         field_label: field_label,
                                                         integration_key: request_params[:integration_key],
                                                         field_key: request_params[:field_key],
                                                         show_meta: show_meta?),
        layout: false
      )
    end
end
