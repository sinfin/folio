# frozen_string_literal: true

class Dummy::Atom::Images::MasonryGallery < Folio::Atom::Base
  ATTACHMENTS = %i[images]

  STRUCTURE = {
    title: :string,
    subtitle: :string,
  }

  ASSOCIATIONS = {}

  validates :image_placements,
            presence: true

  def self.console_insert_row
    CONSOLE_INSERT_ROWS[:images]
  end
end
