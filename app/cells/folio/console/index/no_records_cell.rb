# frozen_string_literal: true

class Folio::Console::Index::NoRecordsCell < Folio::ConsoleCell
  include Folio::Console::Cell::IndexFilters

  def new_link
    url = model[:url].presence || through_aware_console_url_for(model, action: :new, safe: true)

    return if url.nil?

    html_opts = { title: t(".new") }
    link_to(t(".new"), url, html_opts)
  end
end
