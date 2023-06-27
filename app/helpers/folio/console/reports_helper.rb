# frozen_string_literal: true

module Folio::Console::ReportsHelper
  def folio_console_report(model = {}, &block)
    cell("folio/console/reports/index", model, block:).show.html_safe
  end
end
