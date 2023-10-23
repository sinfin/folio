# frozen_string_literal: true

class Folio::Console::Api::AiAssistantController < Folio::Console::Api::BaseController
  include Folio::CstypoHelper

  def generate_response
    prompt = params[:prompt].presence
    record_id = params[:record_id].presence
    record_klass = params[:record_klass].presence

    unless prompt
      render json: {}, status: 400
      return
    end

    prompt = substitute_patterns(prompt, record_id, record_klass)

    response_data = gpt_client.generate_response(prompt, 2000)

    unless response_data["choices"]
      render json: response_data, status: 404
      return
    end

    choices = response_data["choices"].map do |choice|
      status = case choice["finish_reason"]
               when "length"
                 t('.exceeded_max_length')
               when "content_filter"
                 t('.excluded_by_content_filter')
      end

      {
        text: choice.dig("message", "content"),
        index: choice["index"],
        status:
      }
    end

    render json: { prompt: prompt, response: { choices: choices } }
  end

  def gpt_client
    @gpt_client ||= Folio::ChatGptClient.new
  end

  def substitute_patterns(prompt, record_id, record_klass)
    return prompt unless record_id && record_klass

    record = record_klass.constantize.find(record_id)
    patterns = record.try(:ai_assistant_substitute_patterns) || []

    patterns.each do |pattern_data|
      prompt = prompt.gsub(pattern_data[:pattern], pattern_data[:content])
    end

    prompt
  end
end
