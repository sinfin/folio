# frozen_string_literal: true

module Folio::CstypoHelper
  CSTYPO_REGEXP = /(?<![<\/])\b([szkvaiou%]\b) /i

  def cstypo(string, replace_newlines_with_br: false)
    if string.present? && string.is_a?(String)
      runner = string

      if replace_newlines_with_br
        runner = runner.gsub(/(\r\n|\n)/, "<br>")
      end

      if I18n.locale == :cs
        runner = runner.gsub(CSTYPO_REGEXP, '\1&nbsp;')
                       .gsub(/(\d+)\s+(\d+)/, '\1&nbsp;\2')
                       .gsub(/(\d+)\s+(Kč)/, '\1&nbsp;\2')
      end

      runner.html_safe
    else
      string
    end
  end
end
