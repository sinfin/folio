# frozen_string_literal: true

module Folio::Console::IndexHelper
  def index_header(opts = {})
    opts[:pagy] ||= @pagy
    opts[:tabs] ||= index_tabs
    opts[:folio_console_merge] ||= @folio_console_merge
    cell('folio/console/index/header', @klass, opts).show.html_safe
  end
end
