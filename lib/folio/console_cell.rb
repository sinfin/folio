# frozen_string_literal: true

class Folio::ConsoleCell < Folio::ApplicationCell
  include Folio::Console::CellsHelper

  def html_safe_fields_for(f, key, obj = nil, &block)
    f.simple_fields_for key, obj do |subfields|
      (yield subfields).html_safe
    end
  end

  def url_for(*args)
    controller.url_for(*args)
  end
end
