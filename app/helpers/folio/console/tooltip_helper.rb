# frozen_string_literal: true

module Folio
  module Console::TooltipHelper
    def console_tooltip(text: nil, icon: nil, title: nil, link: nil, &block)
      return 'Missing text or icon in console_tooltip helper.' if !text && !icon
      return 'Missing tooltip content (&block).' unless block_given?

      icon = fa_icon(icon) if icon
      content = [icon, text].compact.join(' ').html_safe

      content_tag :span, class: 'f-console-tooltip-wrap', title: title do
        if link
          concat(link_to(content, link))
        else
          concat(content_tag(:span, content))
        end

        concat(content_tag(:div, class: 'f-console-tooltip-content', &block))
      end
    end
  end
end
