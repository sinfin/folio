# frozen_string_literal: true

class Dummy::Atom::Cards::FullWidth < Folio::Atom::Base
  ATTACHMENTS = %i[cover]

  STRUCTURE = {
    title: :string,
    content: :richtext,
    button_url_json: :url_json,
    secondary_button_url_json: :url_json,
  }

  ASSOCIATIONS = {}

  MOLECULE = true

  FORM_LAYOUT = :aside_attachments

  validates :cover_placement,
            :title,
            presence: true

  def self.console_insert_row
    CONSOLE_INSERT_ROWS[:cards]
  end
end
