# frozen_string_literal: true

class Dummy::Atom::Cards::Small < Folio::Atom::Base
  ATTACHMENTS = %i[cover]

  STRUCTURE = {
    title: :string,
    content: :richtext,
    button_url_json: :url_json,
    link_url_json: :url_json,
  }

  ASSOCIATIONS = {}

  FORM_LAYOUT = :aside_attachments

  MOLECULE = true

  validate :validate_one_of_contents

  def self.console_insert_row
    CONSOLE_INSERT_ROWS[:cards]
  end

  private
    def validate_one_of_contents
      if title.blank? && content.blank?
        errors.add(:content, :blank)
      end
    end
end
