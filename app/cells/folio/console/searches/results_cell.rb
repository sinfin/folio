# frozen_string_literal: true

class Folio::Console::Searches::ResultsCell < Folio::ConsoleCell
  def href(result)
    controller.url_for([:console, result, action: :show])
  rescue NoMethodError
    controller.url_for([:edit, :console, result])
  end
end
