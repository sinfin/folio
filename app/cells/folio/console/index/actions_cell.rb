# frozen_string_literal: true

class Folio::Console::Index::ActionsCell < Folio::ConsoleCell
  def show
    @actions = actions_ary

    collapsed_ary = @actions.filter_map do |action|
      action if action[:collapsed]
    end

    if collapsed_ary.size > 1
      @actions.reject! { |action| action[:collapsed] }

      @dropdown_links = collapsed_ary.map do |action|
        href = if action[:url] && !action[:disabled]
          action[:url].is_a?(Proc) ? action[:url].call(model) : action[:url]
        end

        title = t("folio.console.actions.#{action[:name]}")
        icon_options = { class: "text-#{action[:variant] || "reset"}" }
        data = action[:data] || {}
        data[:method] = action[:method] if action[:method]

        if action[:confirm]
          if action[:confirm].is_a?(String)
            data[:confirm] = action[:confirm]
          else
            data[:confirm] = t("folio.console.confirmation")
          end
        else
          data[:confirm] = nil
        end

        action.merge(title:, href:, label: title, icon_options:, data:)
      end
    end

    render
  end

  def safe_url_for(opts)
    controller.url_for(opts)
  rescue StandardError
  end

  def default_actions
    @default_actions ||= {
      destroy: {
        name: :destroy,
        icon: :delete,
        variant: :danger,
        method: :delete,
        confirm: true,
        collapsed: true,
        url: -> (record) { through_aware_console_url_for(record, safe: true) },
      },
      discard: {
        name: :discard,
        icon: :archive,
        variant: :danger,
        method: :delete,
        confirm: true,
        url: -> (record) { through_aware_console_url_for(record, action: :discard, safe: true) },
      },
      undiscard: {
        name: :undiscard,
        icon: :arrow_u_left_top,
        method: :post,
        url: -> (record) { through_aware_console_url_for(record, action: :undiscard, safe: true) },
      },
      edit: {
        name: :edit,
        icon: :edit_box,
        url: -> (record) { through_aware_console_url_for(record, action: :edit, safe: true) },
      },
      new_clone: {
        name: :new_clone,
        icon: :plus_circle_multiple_outline,
        collapsed: true,
        url: -> (record) { through_aware_console_url_for(record, action: :new_clone, safe: true) },
      },
      show: {
        name: :show,
        icon: :eye,
        url: -> (record) { through_aware_console_url_for(record, safe: true) },
      },
      preview: {
        name: :preview,
        icon: :open_in_new,
        skip_can_now: true,
        target: "_blank",
        url: -> (record) { preview_url_for(record) }
      },
      arrange: {
        name: :arrange,
        icon: :format_list_bulleted,
        url: nil,
      },
    }
  end

  def actions_ary
    acts = []

    with_default = (options[:actions].presence || %i[edit destroy])

    with_default.each do |sym_or_hash|
      if sym_or_hash.is_a?(Symbol)
        next if sym_or_hash == :destroy && model.class.try(:indestructible?)
        next if sym_or_hash == :new_clone && !model.class.try(:is_clonable?)
        obj = default_actions[sym_or_hash]
        next if obj.blank?
        next if should_check_can_now?(obj) && !controller.can_now?(sym_or_hash, model)
        acts << obj
      elsif sym_or_hash.is_a?(Hash)
        sym_or_hash.each do |name, obj|
          next if name == :destroy && model.class.try(:indestructible?)
          next if name == :new_clone && !model.class.try(:is_clonable?)
          base = default_actions[name].presence || {}

          rich_obj = if obj.is_a?(Hash)
            base.merge(obj)
          else
            base.merge(url: obj)
          end

          next if should_check_can_now?(rich_obj) && !controller.can_now?(name, model)

          acts << rich_obj
        end
      end
    end

    acts
  end

  def render_actions(acts)
    acts.filter_map do |action|
      data = action[:data] || {}

      if action[:confirm]
        if action[:confirm].is_a?(String)
          data[:confirm] = action[:confirm]
        else
          data[:confirm] = t("folio.console.confirmation")
        end
      else
        data[:confirm] = nil
      end

      class_names = [
        "f-c-index-actions__link",
        "text-#{action[:variant] || "reset"}",
      ]

      if action[:class_name]
        class_names << action[:class_name]
      end

      if action[:cursor]
        class_names << "f-c-index-actions__link--cursor-#{action[:cursor]}"
      end

      if action[:disabled]
        class_names << "f-c-index-actions__link--disabled"
      end

      opts = {
        title: t("folio.console.actions.#{action[:name]}"),
        method: action[:method],
        target: action[:target],
        class: class_names.join(" "),
        data:
      }

      ico = folio_icon(action[:icon], height: action[:icon_height])

      inner_content = if action[:url] && !action[:disabled]
        url = action[:url].is_a?(Proc) ? action[:url].call(model) : action[:url]
        link_to(ico, url, opts)
      else
        content_tag(:span, ico, opts)
      end

      if action[:tooltip].present?
        content_tag(:span, inner_content, { data: stimulus_tooltip(action[:tooltip]) })
      else
        inner_content
      end
    end
  end

  def should_check_can_now?(obj)
    return false if options && options[:skip_can_now]
    return false if obj.is_a?(Hash) && obj[:skip_can_now]
    true
  end
end
