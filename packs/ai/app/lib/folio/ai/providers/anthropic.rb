# frozen_string_literal: true

class Folio::Ai::Providers::Anthropic < Folio::Ai::Providers::Base
  ANTHROPIC_VERSION = "2023-06-01"
  MODELS_ENDPOINT = "https://api.anthropic.com/v1/models"

  class << self
    def list_models(api_key:, timeout: Folio::Ai::Providers::Base::DEFAULT_TIMEOUT)
      parsed = JSON.parse(perform_get(uri: URI(MODELS_ENDPOINT),
                                      headers: model_list_headers(api_key),
                                      timeout:))

      Array(parsed["data"]).filter_map { |item| model_from_item(item) }
    rescue JSON::ParserError
      raise Folio::Ai::ProviderError, "Anthropic model list response is not valid JSON"
    end

    private
      def model_list_headers(api_key)
        {
          "anthropic-version" => ANTHROPIC_VERSION,
          "x-api-key" => api_key,
          "Content-Type" => "application/json",
        }
      end

      def model_from_item(item)
        id = item["id"].to_s
        return if id.blank?
        return unless id.start_with?("claude-")

        Folio::Ai::Providers::Base::Model.new(id:,
                                              label: item["display_name"].presence || id,
                                              created_at: item["created_at"],
                                              metadata: item.except("id", "display_name", "created_at"))
      end
  end

  def build_request(prompt:, field:, suggestion_count:)
    Request.new(uri: URI(endpoint),
                headers:,
                body: request_body(prompt:, field:, suggestion_count:))
  end

  private
    def endpoint
      "https://api.anthropic.com/v1/messages"
    end

    def headers
      {
        "anthropic-version" => ANTHROPIC_VERSION,
        "x-api-key" => api_key,
        "Content-Type" => "application/json",
      }
    end

    def request_body(prompt:, field:, suggestion_count:)
      {
        model:,
        max_tokens: max_tokens_for(field:, suggestion_count:),
        system: json_schema_instruction(suggestion_count),
        messages: [
          { role: "user", content: prompt },
        ],
      }
    end

    def max_tokens_for(field:, suggestion_count:)
      limit = field.character_limit.presence || 1_000
      [limit * suggestion_count * 2, 1_000].max
    end

    def extract_response_text(response_body)
      parsed = JSON.parse(response_body)
      text_chunks = Array(parsed["content"]).filter_map do |content|
        content["text"] if content["type"] == "text"
      end

      text_chunks.join("\n").presence || response_body
    rescue JSON::ParserError
      response_body
    end
end
