# frozen_string_literal: true

# Generates suggestions asynchronously and publishes rendered HTML fragments.

class Folio::Ai::TextSuggestionsJob < Folio::ApplicationJob
  queue_as { Folio::Ai.config.text_suggestions_queue }

  def perform(request_id:, params:)
    @request_id = request_id
    @params = params.to_h.with_indifferent_access

    return unless deliverable?

    MessageBus.publish(Folio::MESSAGE_BUS_CHANNEL,
                       message.to_json,
                       client_ids: [message_bus_client_id])
  rescue Folio::Ai::ProviderError, Folio::Ai::ResponseError => e
    log_failure(e)
    broadcast_error(:provider_error) if deliverable?
  end

  private
    attr_reader :request_id,
                :params

    def deliverable?
      request_id.present? && message_bus_client_id.present?
    end

    def message_bus_client_id
      params[:message_bus_client_id].presence
    end

    def message
      {
        type: self.class.name,
        data: {
          request_id:,
          group: group?,
          component_id:,
          html: rendered_component,
          fragments: {
            component_id => rendered_component,
          },
        },
      }
    end

    def broadcast_error(error_code)
      MessageBus.publish(Folio::MESSAGE_BUS_CHANNEL,
                         error_message(error_code).to_json,
                         client_ids: [message_bus_client_id])
    end

    def error_message(error_code)
      {
        type: self.class.name,
        data: {
          request_id:,
          group: group?,
          component_id:,
          html: rendered_component(error_code:),
          fragments: {
            component_id => rendered_component(error_code:),
          },
        },
      }
    end

    def rendered_component(error_code: nil)
      @rendered_components ||= {}
      cache_key = error_code || :success

      @rendered_components[cache_key] ||= Folio::ApplicationController.renderer.render(
        Folio::Ai::Console::TextSuggestionsComponent.new(component_id:,
                                                         field:,
                                                         suggestions: error_code ? [] : suggestions,
                                                         instructions: params[:instructions],
                                                         error_code:),
        layout: false
      )
    end

    def suggestions
      @suggestions ||= generator.call
    end

    def generator
      Folio::Ai::TextSuggestionGenerator.new(record:,
                                             site:,
                                             record_key: params[:record_key],
                                             field:,
                                             form_snapshot: params[:form_snapshot],
                                             provider:,
                                             user_instruction: params[:instructions],
                                             suggestion_count:)
    end

    def record
      @record ||= record_class&.find_by(id: params[:id])
    end

    def record_class
      return @record_class if defined?(@record_class)

      klass = params[:klass].to_s.safe_constantize
      @record_class = klass if klass && klass < ActiveRecord::Base
    end

    def site
      @site ||= Folio::Site.find_by(id: params[:site_id])
    end

    def field
      params.fetch(:field).to_h.symbolize_keys
    end

    def provider
      @provider ||= begin
        provider_key = site&.respond_to?(:ai_provider) ? site.ai_provider : Folio::Ai.config.default_provider
        provider_model = site&.respond_to?(:ai_model) ? site.ai_model : Folio::Ai.config.default_model(provider_key)

        Folio::Ai.provider_for(key: provider_key,
                               model: provider_model)
      end
    end

    def component_id
      params[:component_id].presence || "folio_ai_#{field[:key]}"
    end

    def group?
      ActiveModel::Type::Boolean.new.cast(params[:group])
    end

    def suggestion_count
      count = params[:suggestion_count].to_i
      count.positive? ? count : Folio::Ai::TextSuggestionGenerator::DEFAULT_SUGGESTION_COUNT
    end

    def log_failure(error)
      Rails.logger.warn(
        "[Folio::Ai] Text suggestions job failed: " \
        "error_class=#{error.class.name} " \
        "request_id=#{request_id} " \
        "record_key=#{params[:record_key]} " \
        "field_key=#{field[:key]}"
      )
    end
end
