# frozen_string_literal: true

require "openai"

class Folio::ChatGptClient
  attr_reader :api_key, :client

  def initialize
    @api_key = ENV["OPENAI_API_KEY"]

    if @api_key.blank?
      fail "Missing OPENAI_API_KEY"
    end

    @client ||= OpenAI::Client.new(api_key: ENV["OPENAI_API_KEY"])
  end

  def generate_completion(prompt, length)
    response = @client.completions(
      engine: "gpt-3.5-turbo-instruct",
      prompt:,
      n: 1,
      max_tokens: length
    )

    log_response(prompt, response)

    response
  end

  def log_response(prompt, response)
    json_obj = { prompt:, response: }.to_json
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
