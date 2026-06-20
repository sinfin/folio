# frozen_string_literal: true

class Dummy::Atom::Forms::Leads::Form < Folio::Atom::Base
  ATTACHMENTS = %i[]

  STRUCTURE = {
    title: :string,
  }

  ASSOCIATIONS = {}

  def self.console_insert_row
    CONSOLE_INSERT_ROWS[:forms]
  end
end
