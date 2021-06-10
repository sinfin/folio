# frozen_string_literal: true

class Folio::Console::Searches::ResultsCell < Folio::ConsoleCell
  def href(result)
    url_for([:console, result, action: :show])
  rescue NoMethodError
    url_for([:edit, :console, result])
  end
end
