# frozen_string_literal: true

module Folio::ApiControllerBase
  extend ActiveSupport::Concern

  included do
    respond_to :json
    rescue_from StandardError, with: :render_error
  end

  private
    def render_json(data)
      render json: { data: data }, root: false
    end

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

    def render_record(model, serializer = nil, include: [], meta: nil)
      serializer ||= serializer_for(model)

      if model.valid?
        render json: serializer.new(model, include: include, meta: meta)
                               .serializable_hash
      else
        render_invalid model
      end
    end

    def json_from_records(models, serializer = nil, include: [], meta: nil)
      serializer ||= serializer_for(models.first)
      serializer.new(models, include: include, meta: meta)
                .serializable_hash
    end

    def render_records(models, serializer = nil, include: [], meta: nil)
      render json: json_from_records(models,
                                     serializer,
                                     include: include,
                                     meta: meta)
    end

    def render_invalid(model)
      errors = model.errors.full_messages.map do |msg|
        {
          status: 400,
          title: "ActiveRecord::RecordInvalid",
          detail: msg,
        }
      end

      render json: { errors: errors }, status: 400
    end

    def render_selectize_options(models)
      ary = models.map do |model|
        { id: model.id, text: model.to_console_label, value: model.id }
      end
      render json: { data: ary }
    end

    def render_select2_options(models)
      ary = models.map do |model|
        { id: model.id, text: model.to_console_label }
      end
      render json: { results: ary }
    end

    def serializer_for(model)
      serializer = "#{model.class.name}Serializer".safe_constantize
      fail ArgumentError.new("Unknown serializer") if serializer.nil?
      serializer
    end

    def meta_from_pagy(pagy_data)
      {
        page: pagy_data.page,
        pages: pagy_data.pages,
        from: pagy_data.from,
        to: pagy_data.to,
        count: pagy_data.count,
      }
    end
end
