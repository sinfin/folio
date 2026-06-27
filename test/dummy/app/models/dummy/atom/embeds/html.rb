# frozen_string_literal: true

class Dummy::Atom::Embeds::Html < Folio::Atom::Base
  ATTACHMENTS = %i[]

  STRUCTURE = {
    embed_code: :code,
  }

  ASSOCIATIONS = {}

  validates :embed_code,
            presence: true

  def self.console_insert_row
    CONSOLE_INSERT_ROWS[:embeds]
  end
end
