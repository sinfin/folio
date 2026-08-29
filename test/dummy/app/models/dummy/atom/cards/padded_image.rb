# frozen_string_literal: true

class Dummy::Atom::Cards::PaddedImage < Folio::Atom::Base
  ATTACHMENTS = %i[cover]

  STRUCTURE = {
    title: :string,
    description: :text,
    url_json: :url_json,
  }

  ASSOCIATIONS = {}

  MOLECULE = true

  FORM_LAYOUT = :aside_attachments

  validates :title,
            :cover_placement,
            :url_json,
            presence: true

  def self.console_insert_row
    CONSOLE_INSERT_ROWS[:cards]
  end
end
