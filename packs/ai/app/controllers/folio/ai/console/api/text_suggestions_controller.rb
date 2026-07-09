# frozen_string_literal: true

# Starts suggestion jobs and returns loading or validation fragments as JSON.

class Folio::Ai::Console::Api::TextSuggestionsController < Folio::Console::Api::BaseController
  def create
    suggestion_request = text_suggestion_request

    if suggestion_request.ready?
      enqueue_text_suggestions_job(suggestion_request)
    else
      render_component_json(text_suggestions_component(suggestion_request, error_code: suggestion_request.error_code),
                            status: :unprocessable_entity)
    end
  end

  private
    def text_suggestion_request
      Folio::Ai::TextSuggestionRequest.new(params: request_params,
                                           current_user: Folio::Current.user,
                                           current_site: Folio::Current.site,
                                           current_ability: current_ability)
    end

    def request_params
      params.to_unsafe_h.except("controller", "action", "format")
    end

    def enqueue_text_suggestions_job(suggestion_request)
      suggestion_request.persist_instructions! if request_params.key?("instructions")

      request_id = SecureRandom.urlsafe_base64(18)
      Folio::Ai::TextSuggestionsJob.perform_later(request_id:,
                                                  params: suggestion_request.job_params)

      render_component_json(text_suggestions_component(suggestion_request, loading: true),
                            meta: {
                              request_id:,
                              component_id: suggestion_request.component_id,
                              grouped: suggestion_request.grouped?,
                              fragments: loading_fragments(suggestion_request),
                            })
    end

    def text_suggestions_component(suggestion_request, loading: false, error_code: nil)
      Folio::Ai::Console::TextSuggestionsComponent.new(component_id: suggestion_request.component_id,
                                                       field: component_field(suggestion_request),
                                                       instructions: suggestion_request.instructions,
                                                       loading:,
                                                       error_code:,
                                                       show_instructions: !suggestion_request.grouped?)
    end

    def component_field(suggestion_request)
      suggestion_request.field || {
        key: suggestion_request.key.presence || "unknown",
      }
    end

    def loading_fragments(suggestion_request)
      return {} unless suggestion_request.grouped?

      suggestion_request.fields.to_h do |field|
        [
          field.fetch(:component_id),
          render_to_string(Folio::Ai::Console::TextSuggestionsComponent.new(component_id: field.fetch(:component_id),
                                                                            field:,
                                                                            loading: true,
                                                                            show_instructions: false,
                                                                            show_close: false,
                                                                            grouped: true,
                                                                            loading_suggestion_count: Folio::Ai::GROUPED_SUGGESTION_COUNT),
                           layout: false),
        ]
      end
    end
end
