# frozen_string_literal: true

class Dummy::Atom::Cards::Medium < Folio::Atom::Base
  ATTACHMENTS = %i[cover]

  STRUCTURE = {
    title: :string,
    content: :richtext,
    url_json: :url_json,
  }

  ASSOCIATIONS = {}

  FORM_LAYOUT = :aside_attachments

  MOLECULE = true

  validates :content,
            presence: true

  def self.console_insert_row
    CONSOLE_INSERT_ROWS[:cards]
  end
end
