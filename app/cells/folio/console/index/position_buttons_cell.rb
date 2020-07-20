# frozen_string_literal: true

class Folio::Console::Index::PositionButtonsCell < Folio::ConsoleCell
  def url
    options[:url] || default_url
  end

  def as
    options[:as] || model.class.table_name.gsub('folio_', '')
  end

  def attribute
    options[:attribute] || :position
  end

  def default_url
    controller.url_for([:set_positions, :console, model.class])
  end

  def input_class_name
    if model.class.try(:folio_positionable_descending?)
      'f-c-index-position__input f-c-index-position__input--descending'
    else
      'f-c-index-position__input'
    end
  end
end
