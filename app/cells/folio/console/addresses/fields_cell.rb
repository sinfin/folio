# frozen_string_literal: true

class Folio::Console::Addresses::FieldsCell < Folio::ConsoleCell
  include ActionView::Helpers::FormOptionsHelper

  def cols
    options[:cols] || [
      [Folio::Address::Primary, :primary_address, nil],
      [Folio::Address::Secondary, :secondary_address, :use_secondary_address],
    ]
  end

  def fields_layout(g, key)
    options[:fields_layout] && options[:fields_layout][key] || g.object.class.fields_layout
  end

  def input(g, key, address_required: true)
    required = address_required ? nil : false

    # FIXME: address doesn't know it's placement at this moment, can't change validation according to the placement class
    if options[:required] && options[:required].include?(key)
      required = true
    end

    if key == :country_code
      g.input(key, only: g.object.class.countries_whitelist,
                   priority: g.object.class.priority_countries,
                   include_blank: false)
    else
      g.input(key, required:)
    end
  end

  def address_required?(key, attributes)
    return true if model.object.send("should_validate_#{key}?")
    all_blank = attributes.all? { |attr, val| attr == "type" || val.blank? }
    !all_blank
  end
end
