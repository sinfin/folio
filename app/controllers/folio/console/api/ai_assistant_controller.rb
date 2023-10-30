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
    response_data = gpt_client.generate_response(prompt, 1000)

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
        text = choice.dig(:message, :content)
        status = case choice[:finish_reason]
                 when "length"
                   t(".exceeded_max_length")
                 when "content_filter"
                   t(".excluded_by_content_filter")
        end

        {
          content_parts: parse_message_content(text),
          index: choice[:index],
          status:
        }
      end
    end

    def parse_message_content(text)
      if text.match?(/{.*}/m)
        json_start = text.index("{")
        json_end = text.rindex("}")
        json_string = text[json_start..json_end]

        begin
          before_json = { val: text[0..json_start - 1], type: :text } if json_start > 0
          after_json = { val: text[json_end + 1..-1], type: :text } if json_end < text.length - 1

          return [
            before_json,
            { val: JSON.parse(json_string), type: :json },
            after_json,
          ].compact
        rescue JSON::ParserError => _e
        end
      end

      [{ val: text, type: :text }]
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
