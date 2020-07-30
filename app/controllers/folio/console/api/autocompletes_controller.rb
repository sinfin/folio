# frozen_string_literal: true

class Folio::Console::Api::AutocompletesController < Folio::Console::Api::BaseController
  def show
    klass = params.require(:klass).safe_constantize
    q = params.require(:q)
    p_scope = params[:scope]
    p_order = params[:order_scope]

    if klass &&
       klass < ActiveRecord::Base &&
       klass.respond_to?(:by_query) &&
       klass.new.respond_to?(:to_autocomplete_label)

      scope = klass.all

      if p_scope.present? && scope.respond_to?(p_scope)
        scope = scope.send(p_scope)
      end

      scope = scope.by_query(q) if q.present?

      if p_order.present? && scope.respond_to?(p_order)
        scope = scope.unscope(:order).send(p_order)
      end

      scope = scope.limit(25)
                   .map(&:to_autocomplete_label)
                   .compact
                   .uniq
                   .first(10)

      render json: { data: scope }
    else
      render json: { data: [] }
    end
  end

  def field
    klass = params.require(:klass).safe_constantize
    field = params.require(:field)
    q = params[:q]

    if klass && klass.column_names.include?(field)
      scope = klass.unscope(:order)
      scope = scope.where("#{field} ILIKE ?", "%#{q}%") if q.present?

      ary = scope.limit(10)
                 .select("DISTINCT(#{field})")
                 .map { |r| r.send(field) }
                 .compact

      render json: { data: ary }
    else
      render json: { data: [] }
    end
  end

  def selectize
    klass = params.require(:klass).safe_constantize
    q = params[:q]
    p_scope = params[:scope]
    p_order = params[:order_scope]

    if klass && klass < ActiveRecord::Base && klass.respond_to?(:by_query)
      scope = klass.all

      if p_scope.present? && scope.respond_to?(p_scope)
        scope = scope.send(p_scope)
      end

      scope = scope.by_query(q) if q.present?

      if p_order.present? && scope.respond_to?(p_order)
        scope = scope.unscope(:order).send(p_order)
      end

      render_selectize_options(scope.limit(25))
    else
      render json: { data: [] }
    end
  end

  def react_select
    class_names = params.require(:class_names).split(',')
    q = params[:q]
    p_scope = params[:scope]
    p_order = params[:order_scope]

    if class_names
      response = []

      show_model_names = class_names.size > 1

      class_names.each do |class_name|
        klass = class_name.safe_constantize
        if klass && klass < ActiveRecord::Base
          scope = klass.all

          if p_scope.present? && scope.respond_to?(p_scope)
            scope = scope.send(p_scope)
          end

          if q.present?
            scope = scope.by_query(q)
          else
            scope = scope.all
          end

          if klass.respond_to?(:filter_by_atom_form_fields)
            scope = scope.filter_by_atom_form_fields(params[:atom_form_fields] || {})
          end

          if p_order.present? && scope.respond_to?(p_order)
            scope = scope.unscope(:order).send(p_order)
          end

          response += scope.first(30).map do |record|
            text = record.to_console_label
            text = "#{klass.model_name.human} - #{text}" if show_model_names

            {
              id: record.id,
              text: text,
              label: text,
              value: Folio::Console::StiHelper.sti_record_to_select_value(record),
              type: klass.to_s
            }
          end
        end
      end

      render json: { data: response }
    else
      render json: { data: [] }
    end
  end
end
