# frozen_string_literal: true

require "openai"

class Folio::ChatGptClient
  attr_reader :api_key, :client

  def initialize
    @api_key = ENV["OPENAI_API_KEY"]

    if @api_key.blank?
      fail "Missing OPENAI_API_KEY"
    end

    @client ||= OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
  end

  def generate_response(prompt, length)
    start_time = Time.now
    response = @client.chat(
      parameters: {
        model: "gpt-3.5-turbo-16k",
        messages: [{ role: "user", content: prompt }],
        n: 1,
        max_tokens: length,
        temperature: 0.7,
      }
    )
    end_time = Time.now

    log_response(prompt, response, end_time - start_time)

    response
  end

  def log_response(prompt, response, duration)
    json_obj = { prompt:, response:, duration: }.to_json
    finish_reason = response.try(:choices).try(:first).try(:finish_reason)

    if finish_reason == "stop"
      Rails.logger.info("GPT Completion: #{json_obj.to_s}")
    elsif finish_reason == "length"
      Rails.logger.warn("GPT Completion: #{json_obj.to_s}")
    else
      Rails.logger.error("GPT Completion: #{json_obj.to_s}")
    end
  end
end
