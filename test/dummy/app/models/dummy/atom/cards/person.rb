# frozen_string_literal: true

class Dummy::Atom::Cards::Person < Folio::Atom::Base
  ATTACHMENTS = %i[cover]

  STRUCTURE = {
    name: :string,
    job: :string,
    content: :richtext,
    link_url_json: :url_json,
    large: :boolean,
  }

  ASSOCIATIONS = {}

  MOLECULE = true

  FORM_LAYOUT = :aside_attachments

  validates :name,
            :job,
            presence: true

  def self.console_insert_row
    CONSOLE_INSERT_ROWS[:cards]
  end
end
