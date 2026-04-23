# frozen_string_literal: true

class Folio::Ai::Providers::Anthropic < Folio::Ai::Providers::Base
  ANTHROPIC_VERSION = "2023-06-01"

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
