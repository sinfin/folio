# frozen_string_literal: true

class Folio::Console::Leads::CatalogueCell < Folio::ConsoleCell
  include Folio::Console::IndexHelper

  def show
    @klass = Folio::Lead
    render
  end
end
