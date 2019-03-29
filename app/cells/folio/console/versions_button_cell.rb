# frozen_string_literal: true

class Folio::Console::VersionsButtonCell < Folio::ConsoleCell
  def show
    render unless model.new_record?
  end

  def versions_url
    url_for([:console, model, Folio::Version])
  end
end
