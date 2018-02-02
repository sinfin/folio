# frozen_string_literal: true

module Folio
  module Console::BootstrapHelper
    def nav_item_link_to(model, path, opts = {}, active = false, &block)
      title = model.model_name.human(count: 2)

      klass = 'nav-item'
      klass += ' active' if active || current_page?(path)

      opts[:class] = opts[:class].to_s + ' nav-link'
      opts[:class] += ' active'  if active || current_page?(path)

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

    def dropdown(links, class_name: 'btn btn-light btn-sm')
      if links.empty?
        nil
      elsif links.size == 1
        main = links.first
        opts = main.opts.reverse_merge(class: class_name)
        link_to main.title, main.url, opts
      else
        main = links.shift
        render partial: 'admin/partials/dropdown', locals: {
          class_name: class_name,
          main: main,
          links: links
        }
      end
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
