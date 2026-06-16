# frozen_string_literal: true

class Dummy::Atom::Contents::Documents < Folio::Atom::Base
  ALLOWED_SIZES = %w[small medium large]

  ATTACHMENTS = %i[documents]

  STRUCTURE = {
    size: ALLOWED_SIZES,
  }

  ASSOCIATIONS = {}

  after_initialize do
    self.size ||= "medium"
  end

  validates :document_placements,
            presence: true

  def size_with_fallback
    size.presence || "medium"
  end

  def self.default_atom_values
    {
      size: "medium",
    }
  end

  def self.console_insert_row
    CONSOLE_INSERT_ROWS[:contents]
  end
end
