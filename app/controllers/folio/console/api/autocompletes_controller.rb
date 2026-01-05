# frozen_string_literal: true

class Folio::Console::Api::AutocompletesController < Folio::Console::Api::BaseController
  AUTOCOMPLETE_PAGY_ITEMS = 25

  def show
    klass = params.require(:klass).safe_constantize
    q = params[:q]
    p_order = params[:order_scope]
    p_page = params[:page]&.to_i || 1

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

      scope, has_type_ordering = apply_ordered_for_folio_console_selects(scope, klass)

      if p_order.present? && scope.respond_to?(p_order)
        if has_type_ordering
          # Type ordering is primary, add p_order as secondary
          scope = scope.send(p_order)
        else
          # No type ordering, unscope and apply p_order as primary
          scope = scope.unscope(:order).send(p_order)
        end
      elsif q.blank? && p_order.blank? && scope.respond_to?(:ordered)
        # No query and no order scope, use default ordered scope
        if has_type_ordering
          # Type ordering is primary, add ordered as secondary
          scope = scope.ordered
        else
          # No type ordering, unscope and apply ordered as primary
          scope = scope.unscope(:order).ordered
        end
      end

      pagination, records = pagy(scope, page: p_page, items: AUTOCOMPLETE_PAGY_ITEMS)
      scope = records.filter_map(&:to_autocomplete_label).uniq

      render json: { data: scope, meta: meta_from_pagy(pagination) }
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
         klass.included_modules.include?(Folio::File::HasUsageConstraints) &&
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

      scope, has_type_ordering = apply_ordered_for_folio_console_selects(scope, klass)

      if p_order.present? && scope.respond_to?(p_order)
        if has_type_ordering
          scope = scope.send(p_order)
        else
          scope = scope.unscope(:order).send(p_order)
        end
      elsif q.blank? && p_order.blank? && scope.respond_to?(:ordered)
        if has_type_ordering
          scope = scope.ordered
        else
          scope = scope.unscope(:order).ordered
        end
      end

      render_selectize_options(scope.limit(AUTOCOMPLETE_PAGY_ITEMS), label_method: params[:label_method])
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

      scope, has_type_ordering = apply_ordered_for_folio_console_selects(scope, klass)

      if p_order.present? && scope.respond_to?(p_order)
        if has_type_ordering
          scope = scope.send(p_order)
        else
          scope = scope.unscope(:order).send(p_order)
        end
      elsif q.blank? && p_order.blank? && scope.respond_to?(:ordered)
        if has_type_ordering
          scope = scope.ordered
        else
          scope = scope.unscope(:order).ordered
        end
      end

      if klass.respond_to?(:folio_console_select2_includes)
        scope = scope.includes(*klass.folio_console_select2_includes)
      end

      pagination, records = pagy(scope, items: AUTOCOMPLETE_PAGY_ITEMS)

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
    p_page = params[:page]&.to_i || 1

    if class_names
      # Show model names when there are multiple classes, or when a single class forces it
      show_model_names = class_names.size > 1

      # For single class, use pagy; for multiple classes, collect all then paginate array
      if class_names.size == 1
        class_name = class_names.first
        klass = class_name.safe_constantize
        if klass && klass < ActiveRecord::Base
          # Check if class forces showing model names (e.g., STI base classes with multiple types)
          show_model_names ||= klass.try(:folio_console_force_show_model_names_in_react_select?)

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

          scope, has_type_ordering = apply_ordered_for_folio_console_selects(scope, klass)

          if p_order.present? && scope.respond_to?(p_order)
            if has_type_ordering
              scope = scope.send(p_order)
            else
              scope = scope.unscope(:order).send(p_order)
            end
          elsif q.blank? && p_order.blank? && scope.respond_to?(:ordered)
            if has_type_ordering
              scope = scope.ordered
            else
              scope = scope.unscope(:order).ordered
            end
          end

          scope = filter_by_atom_setting_params(scope)

          pagination, records = pagy(scope, page: p_page, items: AUTOCOMPLETE_PAGY_ITEMS)

          response = records.map do |record|
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

          render json: { data: response, meta: meta_from_pagy(pagination) }
          return
        end
      else
        # Multiple classes: collect from each, then paginate combined array
        all_records = []

        class_names.each do |class_name|
          klass = class_name.safe_constantize
          if klass && klass < ActiveRecord::Base

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

            scope, has_type_ordering = apply_ordered_for_folio_console_selects(scope, klass)

            if p_order.present? && scope.respond_to?(p_order)
              if has_type_ordering
                scope = scope.send(p_order)
              else
                scope = scope.unscope(:order).send(p_order)
              end
            elsif q.blank? && p_order.blank? && scope.respond_to?(:ordered)
              if has_type_ordering
                scope = scope.ordered
              else
                scope = scope.unscope(:order).ordered
              end
            end

            scope = filter_by_atom_setting_params(scope)

            # Get enough records to cover pagination (estimate pages needed)
            # For simplicity, get AUTOCOMPLETE_PAGY_ITEMS * 2 from each class
            all_records += scope.limit(AUTOCOMPLETE_PAGY_ITEMS * 2).to_a
          end
        end

        # Paginate the combined array manually
        total_count = all_records.size
        total_pages = (total_count.to_f / AUTOCOMPLETE_PAGY_ITEMS).ceil
        offset = (p_page - 1) * AUTOCOMPLETE_PAGY_ITEMS
        paginated_records = all_records[offset, AUTOCOMPLETE_PAGY_ITEMS] || []

        response = paginated_records.map do |record|
          text = record.to_console_label
          text = "#{text} – #{record.class.model_name.human}" if show_model_names

          {
            id: record.id,
            text:,
            label: text,
            value: Folio::Console::StiHelper.sti_record_to_select_value(record),
            type: record.class.to_s
          }
        end

        # Create pagination meta manually
        pagination_meta = {
          page: p_page,
          pages: total_pages,
          from: offset + 1,
          to: [offset + AUTOCOMPLETE_PAGY_ITEMS, total_count].min,
          count: total_count,
          next: p_page < total_pages ? p_page + 1 : nil
        }

        render json: { data: response, meta: pagination_meta }
        return
      end

      render json: { data: [] }
    else
      render json: { data: [] }
    end
  end

  private
    def apply_ordered_for_folio_console_selects(scope, klass)
      return [scope, false] unless klass.respond_to?(:ordered_for_folio_console_selects)

      # Store existing order values before unscope
      existing_order = scope.order_values.dup
      # Unscope order and apply type ordering as primary
      scope = scope.unscope(:order).ordered_for_folio_console_selects
      # Re-apply existing order as secondary ordering
      if existing_order.present?
        scope = scope.order(existing_order)
      end

      [scope, true]
    end

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
