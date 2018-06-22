# frozen_string_literal: true

module Folio
  module Console::TabsHelper
    def tabs(keys)
      if keys.present? && keys.size > 1
        render 'folio/console/partials/tabs', keys: keys
      end
    end

    def tab(key, active: false, &block)
      content_tag(:div, class: "tab-pane #{active || key == :content ? 'active' : ''}",
                        id: "tab-#{key}",
                        &block)
    end
  end
end
