# frozen_string_literal: true

class ApplicationCell < Folio::ApplicationCell
  def icon(key, opts = {})
    cell("dummy/ui/icon", key, opts)
  end
end
