# frozen_string_literal: true

class Folio::Ai::Console::TextSuggestionsGroupComponent < Folio::Console::ApplicationComponent
  def initialize(integration_key:,
                 field_key:,
                 site: Folio::Current.site,
                 request_timeout_ms: Folio::Ai.config.client_request_timeout_ms)
    @integration_key = integration_key.to_s
    @field_key = field_key.to_s
    @site = site
    @request_timeout_ms = request_timeout_ms
  end

  private
    def component_data
      stimulus_controller("f-ai-c-text-suggestions-group",
                          values: {
                            url: batch_text_suggestions_url,
                            instructions_url: batch_instructions_url,
                            integration_key: @integration_key,
                            field_key: @field_key,
                            request_timeout_ms: @request_timeout_ms,
                            generic_error_text: label(:generic_error_text),
                            request_timeout_text: label(:request_timeout_text),
                            state: "idle",
                          },
                          action: {
                            "keydown@window": "onWindowKeydown",
                            "f-ai-c-text-suggestions-group/message": "onMessage",
                            "f-ai-c-text-suggestions-group-controls:generate": "generate",
                            "f-ai-c-text-suggestions-group-controls:close": "close",
                            "f-ai-c-text-suggestions-group-instructions:regenerate": "regenerate",
                          })
    end

    def render_controls?
      available?
    end

    def available?
      @available ||= Folio::Ai::Availability.new(site: @site,
                                                 integration_key: @integration_key,
                                                 field_key: @field_key).call.available?
    end

    def stored_instruction
      return "" if Folio::Current.user.blank? || @site.blank?

      Folio::Ai::UserInstruction.find_or_initialize_for(user: Folio::Current.user,
                                                        site: @site,
                                                        integration_key: @integration_key,
                                                        field_key: @field_key).instruction.to_s
    end

    def batch_text_suggestions_url
      ai_route_proxy.batch_text_suggestions_console_api_ai_text_suggestions_path
    end

    def batch_instructions_url
      ai_route_proxy.batch_instructions_console_api_ai_text_suggestions_path
    end

    def ai_route_proxy
      helpers.respond_to?(:folio) ? helpers.folio : Folio::Engine.routes.url_helpers
    end

    def label(key)
      I18n.t(key, scope: "folio.ai.console.text_suggestions_group_component")
    end
end
