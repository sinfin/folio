# frozen_string_literal: true

class Dummy::Atom::Contents::Divider < Folio::Atom::Base
  ATTACHMENTS = %i[]

  STRUCTURE = {
    variant: %w[default thin thick invisible],
    margin: %w[small medium large extra-large],

  }

  ASSOCIATIONS = {}

  after_initialize do
    self.variant ||= self.class.default_atom_values[:variant]
    self.margin ||= self.class.default_atom_values[:margin]
  end

  def variant_with_fallback
    variant.presence || self.class.default_atom_values[:variant]
  end

  def margin_with_fallback
    margin.presence || self.class.default_atom_values[:margin]
  end

  def self.default_atom_values
    {
      variant: "default",
      margin: "medium",
    }
  end

  def self.console_insert_row
    CONSOLE_INSERT_ROWS[:contents]
  end
end
