# frozen_string_literal: true

require "openai"

AVAILABLE_MODELS = {
  chat: %w(gpt-3.5-turbo gpt-3.5-turbo-16k gpt-4),
  completion: %w(gpt-3.5-turbo-instruct babbage-002 davinci-002)
}.freeze

class Folio::ChatGptClient
  def initialize(model = nil, max_tokens: 1000, number_of_choices: 1)
    @api_key = ENV["OPENAI_API_KEY"]

    if @api_key.blank?
      fail "Missing OPENAI_API_KEY"
    end

    @model ||= if self.class.allowed_models.include?(model)
      model
    else
      self.class.allowed_models.first
    end

    @type =
      @max_tokens = max_tokens
    @number_of_choices = number_of_choices
  end

  def generate_response(prompt)
    response = send_completion_request(request_params)
    response.try(:deep_symbolize_keys!) || {}
  end

  def send_completion_request(params)
    start_time = Time.now

    client.send(completion_type, completion_params)

    duration = Time.now - start_time
    log_response(prompt, response, duration)
  end

  def count_tokens(prompt)
    OpenAI.rough_token_count(prompt)
  end

  def self.allowed_models
    AVAILABLE_MODELS.values.flatten
  end

  def self.allowed_models_for_select
    AVAILABLE_MODELS.map do |model_type, models_keys|
      models_keys.map do |key|
        name = key.tr(".", "-")
        [t(".chat_gpt_client.model.#{model_type}/#{name}"), key]
      end
    end
  end

  private
    def client
      @client ||= OpenAI::Client.new(access_token: @api_key)
    end

    def client_params
      {
        model: @model,
        n: @number_of_choices,
        max_tokens: @max_tokens,
      }
    end

    def log_response(prompt, response, duration)
      json_obj = { prompt:, response:, duration: }.to_json
      Rails.logger.info("GPT Completion: #{json_obj}")
    end
end
