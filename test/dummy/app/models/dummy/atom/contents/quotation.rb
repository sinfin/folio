# frozen_string_literal: true

class Dummy::Atom::Contents::Quotation < Folio::Atom::Base
  ATTACHMENTS = %i[]

  STRUCTURE = {
    content: :richtext,
    title: :string,
    subtitle: :string,
    large: :boolean
  }

  ASSOCIATIONS = {}

  validates :content,
            presence: true

  def self.console_insert_row
    CONSOLE_INSERT_ROWS[:contents]
  end
end
