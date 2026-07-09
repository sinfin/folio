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
          grouped: grouped?,
          component_id:,
          html: primary_rendered_component,
          fragments: rendered_fragments,
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
          grouped: grouped?,
          component_id:,
          html: primary_rendered_component(error_code:),
          fragments: rendered_fragments(error_code:),
        },
      }
    end

    def rendered_fragments(error_code: nil)
      fields.to_h do |field|
        [
          field.fetch(:component_id),
          rendered_component(field:, error_code:),
        ]
      end
    end

    def primary_rendered_component(error_code: nil)
      rendered_component(field: primary_field, error_code:)
    end

    def rendered_component(field:, error_code: nil)
      @rendered_components ||= {}
      cache_key = [field.fetch(:key), error_code || :success]

      @rendered_components[cache_key] ||= Folio::ApplicationController.renderer.render(
        Folio::Ai::Console::TextSuggestionsComponent.new(component_id: field.fetch(:component_id),
                                                         field:,
                                                         suggestions: error_code ? [] : suggestions_for(field),
                                                         instructions: params[:instructions],
                                                         error_code:,
                                                         show_instructions: !grouped?,
                                                         show_close: !grouped?,
                                                         grouped: grouped?),
        layout: false
      )
    end

    def suggestions_for(field)
      @suggestions ||= {}
      @suggestions[field.fetch(:key)] ||= generator(field:).call
    end

    def generator(field:)
      Folio::Ai::TextSuggestionGenerator.new(record:,
                                             site:,
                                             record_key: params[:record_key],
                                             field:,
                                             form_snapshot: params[:form_snapshot],
                                             provider:,
                                             site_prompt: params[:site_prompt],
                                             instructions: params[:instructions],
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

    def primary_field
      fields.first || field.merge(component_id:)
    end

    def fields
      @fields ||= begin
        raw_fields = grouped? ? params[:fields] : nil
        fields = Array(raw_fields).filter_map { |field_config| normalized_field(field_config) }

        fields.presence || [field.merge(component_id:)]
      end
    end

    def normalized_field(field_config)
      field_hash = field_config.to_h.symbolize_keys
      return if field_hash[:key].blank? || field_hash[:component_id].blank?

      field_hash
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

    def grouped?
      ActiveModel::Type::Boolean.new.cast(params[:grouped])
    end

    def suggestion_count
      return Folio::Ai::GROUPED_SUGGESTION_COUNT if grouped?

      count = params[:suggestion_count].to_i
      count.positive? ? count : Folio::Ai::DEFAULT_SUGGESTION_COUNT
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
