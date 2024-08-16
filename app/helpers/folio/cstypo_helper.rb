# frozen_string_literal: true

module Folio::CstypoHelper
  CSTYPO_REGEXP = /(?<![<\/])\b([szkvaiou%]\b) /i

  def cstypo(string)
    if string.present? && string.is_a?(String) && I18n.locale == :cs
      string.gsub(CSTYPO_REGEXP, '\1&nbsp;')
            .gsub(/(\d+)\s+(\d+)/, '\1&nbsp;\2')
            .gsub(/(\d+)\s+(Kč)/, '\1&nbsp;\2')
            .html_safe
    else
      string
    end
  end

  def replace_newlines_with_br(input)
    cstypo(input).gsub(/(\r\n|\n)/, "<br>").html_safe
  end
end
