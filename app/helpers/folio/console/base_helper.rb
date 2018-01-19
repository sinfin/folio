# frozen_string_literal: true

module Folio
  module Console::BaseHelper
    def icon(name, title = nil)
      classes = ['fa', "fa-#{name}"]
      classes << 'fa-mr' if title.present?
      i = %{<i class="#{classes.join(' ')}"></i>}
      [i, title].compact.join(' ').html_safe
    end

    def featured_button(bool)
      button_tag(class: 'btn btn-sm btn-transparent node') do
        featured_icon(bool)
      end
    end

    def published_button(bool)
      button_tag(class: 'btn btn-sm btn-transparent node') do
        on_off_icon(bool)
      end
    end
  end
end
