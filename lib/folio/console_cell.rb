# frozen_string_literal: true

class Folio::ConsoleCell < Folio::ApplicationCell
  include Folio::Console::CellsHelper

  def html_safe_fields_for(f, key, &block)
    f.simple_fields_for key do |subfields|
      (yield subfields).html_safe
    end
  end
end
