# frozen_string_literal: true

class Folio::Console::Api::AutocompletesController < Folio::Console::Api::BaseController
  def show
    klass = params.require(:klass).safe_constantize
    q = params.require(:q)

    if klass &&
       klass.respond_to?(:by_query) &&
       klass.new.respond_to?(:to_autocomplete_label)

      ary = klass.all
      ary = klass.by_query(q) if q.present?
      ary = ary.limit(25)
               .map(&:to_autocomplete_label)
               .compact
               .uniq
               .first(10)

      render json: { data: ary }
    else
      render json: { data: [] }
    end
  end

  def field
    klass = params.require(:klass).safe_constantize
    q = params.require(:q)
    field = params.require(:field)

    if klass && klass.column_names.include?(field)
      ary = klass.unscope(:order)
                 .where("#{field} ILIKE ?", "%#{q}%")
                 .limit(10)
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

    if klass && klass < ActiveRecord::Base && klass.respond_to?(:by_query)
      scope = klass.all
      scope = scope.by_query(q) if q.present?
      render_selectize_options(scope.limit(25))
    else
      render json: { data: [] }
    end
  end

  def react_select
    class_names = params.require(:class_names).split(',')
    q = params[:q]

    if class_names
      response = []

      show_model_names = class_names.size > 1

      class_names.each do |class_name|
        klass = class_name.safe_constantize
        if klass && klass < ActiveRecord::Base
          if q.present?
            scope = klass.by_query(q)
          else
            scope = klass.all
          end

          if klass.respond_to?(:filter_by_atom_form_fields)
            scope = scope.filter_by_atom_form_fields(params[:atom_form_fields] || {})
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
