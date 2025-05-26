# frozen_string_literal: true

module Folio::CstypoHelper
  CSTYPO_REGEXP = /(?<![<\/])\b([szkvaiou%]\b) /i

  def cstypo(string)
    if string.present? && string.is_a?(String)
      runner = string

      if I18n.locale == :cs
        runner = runner.gsub(CSTYPO_REGEXP, '\1 ')
                       .gsub(/(\d+)\s+(\d+|Kč)/, '\1 \2')
      end

      runner
    else
      string
    end
  end
end
