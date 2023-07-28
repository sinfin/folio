# frozen_string_literal: true

module Folio::IconHelper
  def folio_icon(name, opts = {})
    html = cell("folio/ui/icon", name, opts).show
    html.html_safe if html
  end
end
