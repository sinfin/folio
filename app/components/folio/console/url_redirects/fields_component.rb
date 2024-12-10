# frozen_string_literal: true

class Folio::Console::UrlRedirects::FieldsComponent < Folio::Console::ApplicationComponent
  include Folio::Console::FormsHelper

  def initialize(f:)
    @f = f
  end

  def status_code_collection
    Folio::UrlRedirect::STATUS_CODES.map do |k, v|
      ["#{k} - #{v}", k]
    end
  end

  def data
    stimulus_controller("f-c-url-redirects-fields",
                        action: { change: "inputChanged" },
                        values: {
                          demo_loading: false,
                          demo_api_url: "/TODO"
                        })
  end
end
