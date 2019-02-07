# frozen_string_literal: true

class Folio::Console::Searches::ResultsCell < Folio::ConsoleCell
  def href(result)
    controller.url_for([:edit, :console, result])
  end
end
