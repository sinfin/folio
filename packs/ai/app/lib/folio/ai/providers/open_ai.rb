# frozen_string_literal: true

class Folio::Ai::Providers::OpenAi < Folio::Ai::Providers::Base
  MODELS_ENDPOINT = "https://api.openai.com/v1/models"
  IRRELEVANT_MODEL_PATTERN = /(audio|dall-e|embedding|image|moderation|realtime|search|transcribe|tts|whisper)/i

  class << self
    def list_models(api_key:, timeout: Folio::Ai::Providers::Base::DEFAULT_TIMEOUT)
      parsed = JSON.parse(perform_get(uri: URI(MODELS_ENDPOINT),
                                      headers: model_list_headers(api_key),
                                      timeout:))

      Array(parsed["data"]).filter_map { |item| model_from_item(item) }
    rescue JSON::ParserError
      raise Folio::Ai::ProviderError, "OpenAI model list response is not valid JSON"
    end

    private
      def model_list_headers(api_key)
        {
          "Authorization" => "Bearer #{api_key}",
          "Content-Type" => "application/json",
        }
      end

      def model_from_item(item)
        id = item["id"].to_s
        return if id.blank?
        return unless relevant_model_id?(id)

        Folio::Ai::Providers::Base::Model.new(id:,
                                              label: id,
                                              created_at: item["created"],
                                              metadata: item.except("id", "created"))
      end

      def relevant_model_id?(id)
        id.start_with?("gpt-") && !id.match?(IRRELEVANT_MODEL_PATTERN)
      end
  end

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
