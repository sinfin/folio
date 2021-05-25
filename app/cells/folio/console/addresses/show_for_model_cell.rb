# frozen_string_literal: true

class Folio::Console::Addresses::ShowForModelCell < Folio::ConsoleCell
  include ShowFor::Helper

  def cols
    [
      [Folio::Address::Primary, model.primary_address],
      [Folio::Address::Secondary, model.secondary_address],
    ]
  end

  def col_class
    options[:col_class] || "col-lg-4"
  end
end
