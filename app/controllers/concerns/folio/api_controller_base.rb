# frozen_string_literal: true

module Folio::ApiControllerBase
  extend ActiveSupport::Concern

  included do
    respond_to :json
    rescue_from StandardError, with: :render_error
    skip_before_action :handle_crossdomain_devise
    layout false
  end

  private
    def render_json(data)
      render json: { data: }, root: false
    end

    def render_component_json(component, pagy: nil, flash: nil)
      @component = component
      meta = {}

      if pagy
        meta[:pagy] = meta_from_pagy(pagy)
      end

      if flash
        meta[:flash] = flash
      end

      @meta = if meta.present?
        ", \"meta\": #{meta.to_json}"
      end

      render "folio/api_controller_base_json"
    end

    def render_error(e, status: nil)
      if ENV["FOLIO_API_DONT_RESCUE_ERRORS"] && (Rails.env.development? || Rails.env.test?)
        raise e
      end

      Raven.capture_exception(e) if defined?(Raven)

      responses = Rails.configuration.action_dispatch.rescue_responses
      status ||= (responses[e.class.name] || 500)

      errors = [
        {
          status: Rack::Utils::SYMBOL_TO_STATUS_CODE[status] || status,
          title:  e.class.name,
          detail: e.message,
        }
      ]

      render json: { errors: }, status:
    end

    def render_record(model, serializer = nil, include: [], meta: nil)
      serializer ||= serializer_for(model)

      if model.valid?
        render json: serializer.new(model, include:, meta:)
                               .serializable_hash
      else
        render_invalid model
      end
    end

    def json_from_records(models, serializer = nil, include: [], meta: nil)
      serializer ||= serializer_for(models.first)
      serializer.new(models, include:, meta:)
                .serializable_hash
    end

    def render_records(models, serializer = nil, include: [], meta: nil)
      render json: json_from_records(models,
                                     serializer,
                                     include:,
                                     meta:)
    end

    def render_invalid(model)
      errors = model.errors.full_messages.map do |msg|
        {
          status: 400,
          title: "ActiveRecord::RecordInvalid",
          detail: msg,
        }
      end

      render json: { errors: }, status: 400
    end

    def render_selectize_options(models, label_method: nil)
      label_method ||= :to_console_label
      id_method = params[:slug] ? :slug : :id

      ary = models.map do |model|
        {
          id: model.send(id_method),
          text: model.send(label_method),
          label: model.send(label_method),
          value: model.send(id_method)
        }
      end
      render json: { data: ary }
    end

    def render_select2_options(models, label_method: nil, id_method: nil, meta: nil)
      label_method ||= :to_console_label
      id_method ||= if params[:id_method] && models.present? && models.first.class.column_names.include?(params[:id_method])
        params[:id_method]
      elsif params[:slug]
        :slug
      else
        :id
      end

      ary = models.map do |model|
        h = { id: model.send(id_method), text: model.send(label_method) }

        if form_select_data = model.try(:form_select_data)
          h.merge(form_select_data)
        else
          h
        end
      end

      render json: { results: ary, meta: }
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
        next: pagy_data.next,
      }
    end
end
