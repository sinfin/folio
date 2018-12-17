# frozen_string_literal: true

module Folio
  module Console::BootstrapHelper
    def nav_item_link_to(model_or_string, path, opts = {}, active = false, &block)
      if model_or_string.class.name == 'String'
        title = model_or_string
      else
        title = model_or_string.model_name.human(count: 2)
      end

      active_or_subpath = request.fullpath.start_with?(path.split('?').first)

      klass = 'nav-item'
      klass += ' active' if active || active_or_subpath

      opts[:class] = opts[:class].to_s + ' nav-link'
      opts[:class] += ' active'  if active || active_or_subpath

      if block_given?
        content_tag :li, class: klass do
          link_to path, opts, &block
        end
      else
        content_tag :li, class: klass do
          link_to title, path, opts
        end
      end
    end

    def btn_to_js(title, opts = {})
      opts = opts.merge class: 'btn btn-light'
      link_to title, '#', opts
    end

    def tab_href(record)
      "##{dom_id(record)}"
    end

    def card(title = nil, opts = {}, &block)
      vars = { title: title }

      if opts.delete(:table)
        vars[:table] = capture(&block)
      else
        vars[:body] = capture(&block)
      end

      vars[:opts] = opts
      render partial: 'folio/console/partials/card', locals: vars
    end

    def dropdown(title, links, class_name: 'btn btn-secondary', menu_align: :right)
      cell('folio/console/dropdown', title: title,
                                     links: links,
                                     class_name: class_name,
                                     menu_align: menu_align).show
                                                            .try(:html_safe)
    end

    def progress_bar(value, text = nil)
      render partial: 'admin/partials/progress_bar', locals: {
        progress: value,
        text: text
      }
    end

    def fieldset(legend = nil, &block)
      text = capture(&block)
      render 'admin/partials/fieldset', legend: legend, body: text
    end
  end
end
