# frozen_string_literal: true

class ApplicationCell < Folio::ApplicationCell
  def icon(key, size = nil, opts = {})
    cell("dummy/ui/icon", key, opts.merge(size: size))
  end
end
