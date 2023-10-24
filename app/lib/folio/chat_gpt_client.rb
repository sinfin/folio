# frozen_string_literal: true

require "openai"

class Folio::ChatGptClient
  def initialize
    @api_key = ENV["OPENAI_API_KEY"]

    if @api_key.blank?
      fail "Missing OPENAI_API_KEY"
    end
  end

  def generate_response(prompt, length)
    start_time = Time.now
    response = client.chat(
      parameters: {
        model: Rails.application.config.folio_ai_assistant_openai_model,
        messages: [{ role: "user", content: prompt }],
        n: 1,
        max_tokens: length,
        temperature: 0.7,
      }
    )

    duration = Time.now - start_time
    log_response(prompt, response, duration)

    response
  end

  def client
    @client ||= OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
  end

  def log_response(prompt, response, duration)
    json_obj = { prompt:, response:, duration: }.to_json
    Rails.logger.info("GPT Completion: #{json_obj.to_s}")
  end
end
