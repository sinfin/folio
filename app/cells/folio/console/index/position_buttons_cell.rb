# frozen_string_literal: true

class Folio::Console::Index::PositionButtonsCell < Folio::ConsoleCell
  def url
    options[:url] || url
  end

  def as
    options[:as] || model.class.table_name.gsub('folio_', '')
  end

  def url
    controller.url_for([:set_positions, :console, model.class])
  end
end
