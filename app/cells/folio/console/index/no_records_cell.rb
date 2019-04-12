# frozen_string_literal: true

class Folio::Console::Index::NoRecordsCell < Folio::ConsoleCell
  def new_link
    url = url_for([:console, model, action: :new])
    html_opts = { title: t('.new') }
    link_to(t('.new'), url, html_opts)
  rescue NoMethodError
  end
end
