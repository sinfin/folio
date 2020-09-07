# frozen_string_literal: true

class Folio::Console::Index::PositionButtonsCell < Folio::ConsoleCell
  class_name "f-c-index-position", :descending?

  def url
    options[:url] || default_url
  end

  def as
    options[:as] || model.class.table_name.gsub("folio_", "")
  end

  def attribute
    options[:attribute] || :position
  end

  def default_url
    controller.url_for([:set_positions, :console, model.class])
  end

  def descending?
    options[:descending] || model.class.try(:positionable_descending?)
  end
end
