# frozen_string_literal: true

class Folio::Console::VersionsButtonCell < Folio::ConsoleCell
  def versions_url
    url_for([:console, model, Folio::Version])
  end
end
