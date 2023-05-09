# frozen_string_literal: true

module Folio::IconHelper
  def folio_icon(name, opts = {})
    cell("folio/ui/icon", name, opts).show.html_safe
  end
end
