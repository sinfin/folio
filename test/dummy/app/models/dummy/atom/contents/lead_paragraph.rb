# frozen_string_literal: true

class Dummy::Atom::Contents::LeadParagraph < Folio::Atom::Base
  ATTACHMENTS = %i[]

  STRUCTURE = {
    content: :richtext
  }

  ASSOCIATIONS = {}

  validates :content,
            presence: true

  def self.console_insert_row
    CONSOLE_INSERT_ROWS[:contents]
  end
end
