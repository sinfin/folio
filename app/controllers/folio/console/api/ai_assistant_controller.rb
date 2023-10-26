# frozen_string_literal: true

class Folio::Console::Api::AiAssistantController < Folio::Console::Api::BaseController
  include Folio::CstypoHelper

  attr_accessor :responses

  def generate_response
    prompt = params[:prompt].presence

    unless prompt
      render json: {}, status: 400
      return
    end

    prompt = substitute_patterns(prompt)
    # response_data = gpt_client.generate_response(prompt, 2000)
    response_data = {
      choices: [{
        "finish_reason": "stop",
        "index": 0,
        "message": {
          "content": prompt + " " + params[:gpt_model],
          "role": "assistant"
        }
      }],
    }.deep_symbolize_keys!

    if response_data[:choices]
      choices = parse_response_choices(response_data[:choices])

      render json: { prompt:, response: { choices: } }
    else
      render json: response_data, status: 404
    end
  end

  def count_prompt_tokens
    prompt = params[:prompt].presence
    prompt = substitute_patterns(prompt)
    render json: { count: gpt_client.count_tokens(prompt) }
  end

  private
    def parse_response_choices(choices)
      choices.map do |choice|
        status = case choice[:finish_reason]
                 when "length"
                   t(".exceeded_max_length")
                 when "content_filter"
                   t(".excluded_by_content_filter")
        end

        {
          text: choice.dig(:message, :content),
          index: choice[:index],
          status:
        }
      end
    end

    def gpt_client
      @gpt_client ||= Folio::ChatGptClient.new(params[:gpt_model])
    end

    def substitute_patterns(prompt)
      record_id = params[:record_id].presence
      record_klass = params[:record_klass].presence

      if record_id && record_klass
        record = record_klass.constantize.find(record_id)
        patterns = record.class.try(:ai_assistant_substitute_patterns) || []

        patterns.each do |pattern_data|
          content = pattern_data[:get_content_proc].call(record)
          prompt = prompt.gsub(pattern_data[:pattern], content)
        end
      end

      prompt
    end
end
