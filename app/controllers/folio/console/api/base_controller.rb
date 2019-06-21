# frozen_string_literal: true

class Folio::Console::Api::BaseController < Folio::Console::BaseController
  before_action :authenticate_account!
  respond_to :json

  rescue_from StandardError, with: :render_error

  private

    def render_error(e)
      responses = Rails.configuration.action_dispatch.rescue_responses
      status = responses[e.class.name] || 500

      errors = [
        {
          status: Rack::Utils::SYMBOL_TO_STATUS_CODE[status] || status,
          title:  e.class.name,
          detail: e.message,
        }
      ]

      render json: { errors: errors }, status: status
    end

    def render_json(data)
      render json: { data: data }, root: false
    end

    def render_record(model, serializer = nil)
      serializer ||= serializer_for(model)

      if model.valid?
        render json: serializer.new(model).serializable_hash
      else
        render_invalid model
      end
    end

    def render_records(models, serializer = nil)
      serializer ||= serializer_for(models.first)
      render json: serializer.new(models).serializable_hash
    end

    def render_invalid(model)
      errors = model.errors.to_hash.map do |key, msg|
        title = model.class.human_attribute_name(key)

        { status: 400, title: title, detail: msg }
      end

      render json: { errors: errors }, status: 400
    end

    private

      def serializer_for(model)
        name = model.class.name.gsub('Folio::', '')
        serializer = "Folio::Console::#{name}Serializer".safe_constantize
        serializer ||= "#{name}Serializer".safe_constantize
        fail ArgumentError.new('Unknown serializer') if serializer.nil?
        serializer
      end
end
