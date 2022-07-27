# frozen_string_literal: true

class Folio::Console::Addresses::FieldsCell < Folio::ConsoleCell
  include ActionView::Helpers::FormOptionsHelper

  def cols
    options[:cols] || [
      [Folio::Address::Primary, :primary_address, nil],
      [Folio::Address::Secondary, :secondary_address, :use_secondary_address],
    ]
  end

  def input(g, key, required: false)
    if key == :country_code
      g.input(key, priority: g.object.class.priority_countries, required:)
    else
      g.input(key, required:)
    end
  end

  def required?(key, attributes)
    return true if model.object.send("should_validate_#{key}?")
    all_blank = attributes.all? { |attr, val| attr == "type" || val.blank? }
    !all_blank
  end
end
