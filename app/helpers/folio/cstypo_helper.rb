# frozen_string_literal: true

module Folio
  module CstypoHelper
    CSTYPO_REGEXP = /\b([szkvaiou%]\b) /i

    def cstypo(string)
      if I18n.locale == :cs
        string.gsub(CSTYPO_REGEXP, '\1&nbsp;').html_safe
      else
        string
      end
    end
  end
end
