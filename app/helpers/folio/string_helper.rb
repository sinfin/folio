# frozen_string_literal: true

module Folio::StringHelper
  def sanitize(str, options = {})
    if str.present? && str.is_a?(String)
      default_options = { tags: [], attributes: [] }
      merged_options = default_options.merge(options.symbolize_keys)
      ActionController::Base.helpers.sanitize(str, **merged_options)
    else
      str
    end
  end
end
