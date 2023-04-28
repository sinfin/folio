# frozen_string_literal: true

class Folio::Console::Index::ActionsCell < Folio::ConsoleCell
  def safe_url_for(opts)
    controller.url_for(opts)
  rescue StandardError
  end

  def default_actions
    if I18n.available_locales.size > 1
      locale = model.try(:locale) || I18n.default_locale
    else
      locale = nil
    end

    @default_actions ||= {
      destroy: {
        name: :destroy,
        icon: :delete,
        variant: :danger,
        method: :delete,
        confirm: true,
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
        icon: :edit,
        url: -> (record) { through_aware_console_url_for(record, action: :edit, safe: true) },
      },
      show: {
        name: :show,
        icon: :eye,
        url: -> (record) { through_aware_console_url_for(record, safe: true) },
      },
      preview: {
        name: :preview,
        icon: :open_in_new,
        target: "_blank",
        url: -> (record) do
          if record.respond_to?(:published?) && token = record.try(:preview_token)
            safe_url_for([record, locale:, Folio::Publishable::PREVIEW_PARAM_NAME => token])
          else
            safe_url_for([record, locale:])
          end
        end
      },
      arrange: {
        name: :arrange,
        icon: :format_list_bulleted,
        url: nil,
      },
    }
  end

  def actions
    acts = []
    with_default = (options[:actions].presence || %i[edit destroy])

    sort_array_hashes_first(with_default).each do |sym_or_hash|
      if sym_or_hash.is_a?(Symbol)
        next if sym_or_hash == :destroy && model.class.try(:indestructible?)
        next unless controller.can?(sym_or_hash, model)
        acts << default_actions[sym_or_hash]
      elsif sym_or_hash.is_a?(Hash)
        sym_or_hash.each do |name, obj|
          next if name == :destroy && model.class.try(:indestructible?)
          next unless controller.can?(name, model)
          base = default_actions[name].presence || {}
          if obj.is_a?(Hash)
            acts << base.merge(obj)
          else
            acts << base.merge(url: obj)
          end
        end
      end
    end

    acts.filter_map do |action|
      if action[:confirm]
        if action[:confirm].is_a?(String)
          confirmation = action[:confirm]
        else
          confirmation = t("folio.console.confirmation")
        end
      else
        confirmation = nil
      end

      link_to(folio_icon(action[:icon]),
              action[:url].is_a?(Proc) ? action[:url].call(model) : action[:url],
              title: t("folio.console.actions.#{action[:name]}"),
              method: action[:method],
              target: action[:target],
              class: "f-c-index-actions__link text-#{action[:variant] || "reset"}",
              'data-confirm': confirmation)
    end
  end

  def sort_array_hashes_first(ary)
    ary.sort do |a, b|
      if a.is_a?(Hash) && default_actions.exclude?(a.keys.first)
        -1
      elsif b.is_a?(Hash) && default_actions.exclude?(b.keys.first)
        1
      else
        0
      end
    end
  end
end
