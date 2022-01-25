# frozen_string_literal: true

class Folio::Console::Addresses::FieldsCell < Folio::ConsoleCell
  include ActionView::Helpers::FormOptionsHelper

  def cols
    options[:cols] || [
      [Folio::Address::Primary, :primary_address, nil],
      [Folio::Address::Secondary, :secondary_address, :use_secondary_address],
    ]
  end

  def input(g, key)
    if key == :country_code
      g.input(key, priority: g.object.class.priority_countries)
    else
      g.input(key)
    end
  end
end
