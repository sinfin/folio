# frozen_string_literal: true

module Folio::StringHelper
  def sanitize(str)
    if str.present? && str.is_a?(String)
      ActionController::Base.helpers.sanitize(str, tags: [], attributes: [])
    else
      str
    end
  end
end
