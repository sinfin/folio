# frozen_string_literal: true

class Folio::Console::Index::ActionsCell < Folio::ConsoleCell
  def default_actions
    locale = model.try(:locale) || I18n.default_locale

    @default_actions ||= {
      destroy: {
        name: :destroy,
        icon: 'trash-alt',
        button: 'danger',
        method: :delete,
        confirm: true,
        url: begin
               controller.url_for([:console, model])
             rescue StandardError
             end
      },
      edit: {
        name: :edit,
        icon: 'edit',
        button: 'secondary',
        url: begin
               controller.url_for([:edit, :console, model])
             rescue StandardError
             end
      },
      preview: {
        name: :preview,
        icon: 'eye',
        button: 'light',
        target: '_blank',
        url: begin
               controller.main_app.url_for([model, locale: locale])
              rescue
             end
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

    if with_default.include?(:destroy) && model.class.try(:indestructible?)
      with_default = with_default.without(:destroy)
    end

    sort_array_hashes_first(with_default).map do |sym_or_hash|
      if sym_or_hash.is_a?(Symbol)
        acts << default_actions[sym_or_hash]
      elsif sym_or_hash.is_a?(Hash)
        sym_or_hash.each do |name, obj|
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
      confirmation = action[:confirm] ? t('folio.console.confirmation') : nil

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
      if a.is_a?(Hash)
        -1
      elsif b.is_a?(Hash)
        1
      else
        0
      end
    end
  end
end
