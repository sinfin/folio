# frozen_string_literal: true

class Folio::Console::Addresses::FieldsCell < Folio::ConsoleCell
  include ActionView::Helpers::FormOptionsHelper

  def cols
    [
      [Folio::Address::Primary, :primary_address, nil],
      [Folio::Address::Secondary, :secondary_address, :use_secondary_address],
    ]
  end
end
