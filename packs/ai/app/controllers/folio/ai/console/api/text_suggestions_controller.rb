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
                              group: suggestion_request.group?,
                            })
    end

    def text_suggestions_component(suggestion_request, loading: false, error_code: nil)
      Folio::Ai::Console::TextSuggestionsComponent.new(component_id: suggestion_request.component_id,
                                                       field: component_field(suggestion_request),
                                                       instructions: suggestion_request.instructions,
                                                       loading:,
                                                       error_code:)
    end

    def component_field(suggestion_request)
      suggestion_request.field || {
        key: suggestion_request.key.presence || "unknown",
      }
    end
end
