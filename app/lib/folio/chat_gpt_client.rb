# frozen_string_literal: true

require "openai"

DEFAULT_GPT_MODELS = %w(gpt-3.5-turbo-0613 gpt-3.5-turbo-0301 gpt-3.5-turbo-16k-0613 gpt-4-0613 gpt-4-0314).freeze

class Folio::ChatGptClient
  def initialize(model)
    @api_key = ENV["OPENAI_API_KEY"]

    if @api_key.blank?
      fail "Missing OPENAI_API_KEY"
    end

    @model ||= if self.class.allowed_models.include?(model)
      model
    else
      self.class.allowed_models.first
    end
  end

  def generate_response(prompt, length)
    start_time = Time.now
    response = client.chat(
      parameters: {
        model: @model,
        messages: [{ role: "user", content: prompt }],
        n: 1,
        max_tokens: length,
      }
    )

    duration = Time.now - start_time
    log_response(prompt, response, duration)

    response.try(:deep_symbolize_keys!) || {}
  end

  def count_tokens(prompt)
    OpenAI.rough_token_count(prompt)
  end

  def self.allowed_models
    DEFAULT_GPT_MODELS
  end

  private
    def client
      @client ||= OpenAI::Client.new(access_token: @api_key)
    end

    def log_response(prompt, response, duration)
      json_obj = { prompt:, response:, duration: }.to_json
      Rails.logger.info("GPT Completion: #{json_obj}")
    end
end
