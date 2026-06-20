# frozen_string_literal: true

class Dummy::Atom::Listings::Blog::Articles::Index < Folio::Atom::Base
  ATTACHMENTS = %i[]

  STRUCTURE = {}

  ASSOCIATIONS = {}

  VALID_PLACEMENT_TYPES = %w[
    Dummy::Page::Blog::Articles::Index
  ]

  def self.console_insert_row
    CONSOLE_INSERT_ROWS[:listings]
  end
end
