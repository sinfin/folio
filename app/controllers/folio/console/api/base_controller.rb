# frozen_string_literal: true

class Folio::Console::Api::BaseController < Folio::ApplicationController
  before_action :authenticate_account!
  respond_to :json

  rescue_from StandardError, with: :render_error

  private

    def render_error(e)
      status = Rails.configuration.action_dispatch.rescue_responses[e.class.name] || 500

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

    def render_entity(model, entity = nil)
      if entity.nil?
        entity = "Entities::Folio::Console::#{model.class.name}".safe_constantize
        entity ||= "Entities::#{model.class.name}".safe_constantize
        fail ArgumentError.new('Unknown entity') if entity.nil?
      end
      render_json entity.represent(model)
    end
end
