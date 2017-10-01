# frozen_string_literal: true

module Folio
  module UrlHelper
    def active_link_to(title, path, active = nil)
      klass = ' active' if active || current_page?(path)
      link_to(title, path, class: klass)
    end

    def nested_page_url(page)
      page_url(page.parent, child_id: page)
    end
  end
end
