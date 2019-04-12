# frozen_string_literal: true

module Folio
  module CstypoHelper
    CSTYPO_REGEXP = /(?<![<\/])\b([szkvaiou%]\b) /i

    def cstypo(string)
      if I18n.locale == :cs
        string.gsub(CSTYPO_REGEXP, '\1&nbsp;')
              .gsub(/(\d+)\s+(\d+)/, '\1&nbsp;\2')
              .gsub(/(\d+)\s+(Kč)/, '\1&nbsp;\2')
              .html_safe
      else
        string
      end
    end
  end
end
