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
        icon: 'trash-alt',
        button: 'danger',
        method: :delete,
        confirm: true,
        url: safe_url_for([:console, model]),
      },
      discard: {
        name: :discard,
        icon: 'trash-alt',
        button: 'secondary',
        method: :delete,
        confirm: true,
        url: safe_url_for([:discard, :console, model]),
      },
      undiscard: {
        name: :undiscard,
        icon: 'redo-alt',
        button: 'secondary',
        method: :post,
        url: safe_url_for([:undiscard, :console, model]),
      },
      edit: {
        name: :edit,
        icon: 'edit',
        button: 'secondary',
        url: safe_url_for([:edit, :console, model]),
      },
      show: {
        name: :show,
        icon: 'eye',
        button: 'light',
        url: safe_url_for([:console, model]),
      },
      preview: {
        name: :preview,
        icon: 'eye',
        button: 'light',
        target: '_blank',
        url: safe_url_for([model, locale: locale]),
      },
      arrange: {
        name: :arrange,
        icon: 'list',
        button: 'light',
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
        acts << default_actions[sym_or_hash]
      elsif sym_or_hash.is_a?(Hash)
        sym_or_hash.each do |name, obj|
          next if name == :destroy && model.class.try(:indestructible?)
          base = default_actions[name].presence || {}
          if obj.is_a?(Hash)
            acts << base.merge(obj)
          else
            acts << base.merge(url: obj)
          end
        end
      end
    end

    acts.map do |action|
      if action[:confirm]
        if action[:confirm].is_a?(String)
          confirmation = action[:confirm]
        else
          confirmation = t('folio.console.confirmation')
        end
      else
        confirmation = nil
      end

      opts = {
        title: t("folio.console.actions.#{action[:name]}"),
        class: "btn btn-#{action[:button]} fa fa-#{action[:icon]}",
        method: action[:method],
        target: action[:target],
        'data-confirm': confirmation,
      }

      begin
        link_to('', action[:url], opts)
      rescue ActionController::UrlGenerationError
      end
    end.compact
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
