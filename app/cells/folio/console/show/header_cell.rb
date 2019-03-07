# frozen_string_literal: true

class Folio::Console::Show::HeaderCell < Folio::ConsoleCell
  def edit_url
    url_for([:edit, :console, model])
  rescue NoMethodError
  end
end
