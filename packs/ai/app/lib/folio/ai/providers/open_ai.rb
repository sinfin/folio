# frozen_string_literal: true

class Folio::Ai::Providers::OpenAi < Folio::Ai::Providers::Base
  def build_request(prompt:, field:, suggestion_count:)
    Request.new(uri: URI(endpoint),
                headers:,
                body: request_body(prompt:, field:, suggestion_count:))
  end

  private
    def endpoint
      "https://api.openai.com/v1/responses"
    end

    def headers
      {
        "Authorization" => "Bearer #{api_key}",
        "Content-Type" => "application/json",
      }
    end

    def request_body(prompt:, field:, suggestion_count:)
      {
        model:,
        input: [
          { role: "system", content: json_schema_instruction(suggestion_count) },
          { role: "user", content: prompt },
        ],
        metadata: {
          folio_ai_field_key: field.key,
        },
      }
    end

    def extract_response_text(response_body)
      parsed = JSON.parse(response_body)

      parsed["output_text"].presence ||
        output_text(parsed).presence ||
        parsed.dig("choices", 0, "message", "content").presence ||
        response_body
    rescue JSON::ParserError
      response_body
    end

    def output_text(parsed)
      Array(parsed["output"]).filter_map do |item|
        output_item_text(item)
      end.join("\n")
    end

    def output_item_text(item)
      return item["text"] if item["type"] == "output_text" && item["text"].present?

      Array(item["content"]).filter_map do |content|
        content["text"].presence
      end.join("\n").presence
    end
end
