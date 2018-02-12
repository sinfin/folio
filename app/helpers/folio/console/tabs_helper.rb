# frozen_string_literal: true

module Folio
  module Console::TabsHelper
    def tabs(keys)
      render 'folio/console/partials/tabs', keys: keys
    end

    def tab(key, &block)
      content_tag(:div, class: "tab-pane #{key == :content ? 'active' : ''}",
                        id: "tab-#{key}",
                        &block)
    end
  end
end
