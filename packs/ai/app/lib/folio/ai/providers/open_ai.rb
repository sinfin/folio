# frozen_string_literal: true

# Calls OpenAI Responses API and extracts text output for suggestion generation.
class Folio::Ai::Providers::OpenAi < Folio::Ai::Providers::Base
  DEFAULT_MODEL = Folio::Ai::DEFAULT_OPENAI_MODEL
  ENDPOINT = "https://api.openai.com/v1/responses"

  def self.key
    :openai
  end

  def self.available?
    Folio::Ai.openai_api_key.present?
  end

  def initialize(api_key: Folio::Ai.openai_api_key, **kwargs)
    raise Folio::Ai::ProviderError, "FOLIO_AI_OPENAI_API_KEY is missing" if api_key.blank?

    @api_key = api_key
    super(**kwargs)
  end

  def complete(prompt:, suggestion_count: nil)
    response_text(post_json(uri: URI(ENDPOINT),
                            headers:,
                            body: response_body(prompt:))).presence ||
      raise(Folio::Ai::ProviderError, "AI provider response did not include text")
  end

  private
    attr_reader :api_key

    def headers
      {
        "Authorization" => "Bearer #{api_key}",
      }
    end

    def response_body(prompt:)
      {
        model:,
        store: false,
        input: [
          { role: "system", content: "Return only the requested text." },
          { role: "user", content: prompt.to_s },
        ],
      }
    end

    def response_text(parsed)
      return parsed["output_text"] if parsed["output_text"].is_a?(String)

      Array(parsed["output"]).filter_map do |item|
        output_item_text(item)
      end.join("\n")
    end

    def output_item_text(item)
      return unless item["type"] == "message"

      Array(item["content"]).filter_map do |content|
        content["text"].presence if content["type"] == "output_text"
      end.join("\n").presence
    end
end
