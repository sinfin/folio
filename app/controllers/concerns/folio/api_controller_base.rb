# frozen_string_literal: true

module Folio::ApiControllerBase
  extend ActiveSupport::Concern

  include Folio::RenderComponentJson

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

    def render_error(e, status: nil)
      if ENV["FOLIO_API_DONT_RESCUE_ERRORS"] && (Rails.env.development? || Rails.env.test?)
        raise e
      end

      Raven.capture_exception(e) if defined?(Raven)
      Sentry.capture_exception(e) if defined?(Sentry)

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

    def render_record(model, serializer = nil, include: [], meta: nil, flash: nil)
      serializer ||= serializer_for(model)

      if model.valid?
        hash = serializer.new(model, include:)
                         .serializable_hash

        if meta || flash
          hash[:meta] = meta || {}

          if flash
            hash[:meta] = hash[:meta].merge(flash:)
          end
        end

        render json: hash
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

    def render_select2_options(models, label_method: nil, group_method: nil, id_method: nil, meta: nil)
      label_method ||= :to_console_label

      id_method ||= if params[:id_method] && models.present? && models.first.class.column_names.include?(params[:id_method])
        params[:id_method]
      elsif params[:slug]
        :slug
      else
        :id
      end

      ary = if params[:group_method].present? && !params[:q].blank?
        models.group_by(&params[:group_method].to_sym).map do |group_name, group_items|
          children = group_items.map do |child|
            h = { id: child.send(id_method), text: child.send(label_method) }
            if folio_console_select2_data = child.try(:folio_console_select2_data)
              h.merge(folio_console_select2_data)
            else
              h
            end
          end

          { text: group_name, children: }
        end
      else
        models.map do |model|
          h = { id: model.send(id_method), text: model.send(label_method) }

          if folio_console_select2_data = model.try(:folio_console_select2_data)
            h.merge(folio_console_select2_data)
          else
            h
          end
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
