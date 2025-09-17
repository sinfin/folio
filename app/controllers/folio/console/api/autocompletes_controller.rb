# frozen_string_literal: true

class Folio::Console::Api::AutocompletesController < Folio::Console::Api::BaseController
  def show
    klass = params.require(:klass).safe_constantize
    q = params[:q]
    p_order = params[:order_scope]

    if klass &&
       klass < ActiveRecord::Base &&
       klass.respond_to?(:by_label_query) &&
       klass.new.respond_to?(:to_autocomplete_label)

      scope = klass.accessible_by(Folio::Current.ability)

      if !klass.try(:console_api_autocomplete_dont_filter_by_site)
        scope = scope.by_site(Folio::Current.site) if scope.respond_to?(:by_site)
      end
      scope = apply_param_scope(scope)

      params.each do |key, val|
        if key.starts_with?("filter_by_")
          filter_scope_name = key.delete_prefix("filter_")

          if scope.respond_to?(filter_scope_name)
            scope = scope.send(filter_scope_name, val)
          end
        end
      end

      scope = scope.by_label_query(q) if q.present?

      if p_order.present? && scope.respond_to?(p_order)
        scope = scope.unscope(:order).send(p_order)
      end

      scope = scope.limit(25)
                   .filter_map(&:to_autocomplete_label)
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
    q = q.downcase.parameterize if q.present?
    p_order = params[:order_scope]
    p_without = params[:without]

    if klass && klass.column_names.include?(field)
      scope = klass.unscope(:order).where.not(field => nil)
      scope = scope.accessible_by(Folio::Current.ability)

      scope = scope.by_site(Folio::Current.site) if scope.respond_to?(:by_site)
      scope = apply_param_scope(scope)

      if p_without.present?
        scope = scope.where.not(id: p_without.split(","))
      end

      scope = filter_by_atom_setting_params(scope)

      if q.present?
        if scope.respond_to?("by_#{field}")
          scope = scope.send("by_#{field}", q)
        elsif scope.respond_to?("by_#{field}_query")
          scope = scope.send("by_#{field}_query", q)
        else
          scope = scope.where("#{field} ILIKE ?", "%#{q}%")
        end
      end

      ary = if p_order.present? && scope.respond_to?(p_order)
        scope.unscope(:order)
             .send(p_order)
             .distinct(field)
             .limit(10)
             .pluck(field)
      else
        scope.group(field)
             .unscope(:order)
             .order("count_id DESC")
             .limit(10)
             .count("id")
             .keys
      end

      if klass &&
         klass.included_modules.include?(Folio::File::HasMediaSource) &&
         field == "attribution_source"
        media_source_titles = get_media_source_titles_for_autocomplete(q)

        media_source_set = media_source_titles.to_set
        existing_without_media_source = ary.reject { |title| media_source_set.include?(title) }
        ary = media_source_titles + existing_without_media_source
      end

      if q.present?
        ary.select! { |item| item.downcase.parameterize.include?(q) }
      end

      render json: { data: ary.first(10) }
    else
      render json: { data: [] }
    end
  end

  def selectize
    klass = params.require(:klass).safe_constantize
    q = params[:q]
    p_order = params[:order_scope]
    p_without = params[:without]

    if klass && klass < ActiveRecord::Base && klass.respond_to?(:by_label_query)
      scope = klass.accessible_by(Folio::Current.ability)

      scope = scope.by_site(Folio::Current.site) if scope.respond_to?(:by_site)
      scope = apply_param_scope(scope)

      if p_without.present?
        scope = scope.where.not(id: p_without.split(","))
      end

      scope = filter_by_atom_setting_params(scope)

      scope = scope.by_label_query(q) if q.present?

      if p_order.present? && scope.respond_to?(p_order)
        scope = scope.unscope(:order).send(p_order)
      end

      render_selectize_options(scope.limit(25), label_method: params[:label_method])
    else
      render_selectize_options([])
    end
  end

  def select2
    klass = params.require(:klass).safe_constantize
    q = params[:q]
    p_order = params[:order_scope]
    p_without = params[:without]

    if klass && klass < ActiveRecord::Base && klass.respond_to?(:by_label_query)
      scope = klass.accessible_by(Folio::Current.ability)

      scope = scope.by_site(Folio::Current.site) if scope.respond_to?(:by_site)
      scope = apply_param_scope(scope)

      if p_without.present?
        scope = scope.where.not(id: p_without.split(","))
      end

      scope = filter_by_atom_setting_params(scope)

      scope = scope.by_label_query(q) if q.present?

      if p_order.present? && scope.respond_to?(p_order)
        scope = scope.unscope(:order).send(p_order)
      end

      if klass.respond_to?(:folio_console_select2_includes)
        scope = scope.includes(*klass.folio_console_select2_includes)
      end

      pagination, records = pagy(scope, items: 25)

      render_select2_options(records,
                             label_method: params[:label_method],
                             group_method: params[:group_method],
                             meta: meta_from_pagy(pagination))
    else
      render_select2_options([])
    end
  end

  def react_select
    class_names = params.require(:class_names).split(",")
    q = params[:q]
    p_order = params[:order_scope]
    p_without = params[:without]

    if class_names
      response = []

      show_model_names = class_names.size > 1

      class_names.each do |class_name|
        klass = class_name.safe_constantize
        if klass && klass < ActiveRecord::Base
          show_model_names ||= klass.try(:folio_console_show_model_names_in_react_select?)

          scope = klass.accessible_by(Folio::Current.ability)

          scope = scope.by_site(Folio::Current.site) if scope.respond_to?(:by_site)
          scope = apply_param_scope(scope)

          if p_without.present?
            scope = scope.where.not(id: p_without.split(","))
          end

          if q.present?
            scope = scope.by_label_query(q)
          else
            scope = scope.all
          end

          if klass.respond_to?(:filter_by_atom_form_fields)
            scope = scope.filter_by_atom_form_fields(params[:atom_form_fields] || {})
          end

          if p_order.present? && scope.respond_to?(p_order)
            scope = scope.unscope(:order).send(p_order)
          end

          scope = filter_by_atom_setting_params(scope)

          response += scope.first(30).map do |record|
            text = record.to_console_label
            text = "#{text} – #{record.class.model_name.human}" if show_model_names

            {
              id: record.id,
              text:,
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

  private
    def filter_by_atom_setting_params(scope)
      params.keys.each do |key|
        next unless key.starts_with?("by_atom_setting_")
        if scope.respond_to?(key)
          scope = scope.send(key, params[key])
        end
      end

      scope
    end

    def default_apply_param_scope(scope)
      p_scope = params[:scope]

      if p_scope.present? && scope.respond_to?(p_scope)
        scope = scope.send(p_scope)
      end

      scope
    end

    def apply_param_scope(scope)
      default_apply_param_scope(scope)
    end

    def get_media_source_titles_for_autocomplete(q)
      scope = Folio::MediaSource.accessible_by(Folio::Current.ability)

      unless Rails.application.config.folio_shared_files_between_sites
        scope = scope.by_site(Folio::Current.site) if scope.respond_to?(:by_site)
      end

      if q.present?
        scope = scope.where("title ILIKE ?", "%#{q}%")
      end

      scope.pluck(:title).compact
    end
end
