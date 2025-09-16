# frozen_string_literal: true

class Folio::Console::Files::MediaSourceSelectComponent < Folio::Console::ApplicationComponent
  def initialize(file:)
    @file = file
  end

  def autocomplete_url
    helpers.select2_console_api_autocomplete_url(klass: "Folio::MediaSource", only_path: true)
  end

  def form_url
    url_for([:console, @file])
  end

  def data
    stimulus_controller("f-c-files-media-source-select")
  end
end
