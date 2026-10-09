# frozen_string_literal: true

class Folio::Atom::Audited::Invalid < Folio::Atom::Base
  ATTACHMENTS = %i[]

  STRUCTURE = {
    atom_validation_errors: :text,
    atom_audited_hash_json: :text,
  }

  ASSOCIATIONS = {}

  validates :atom_validation_errors,
            :atom_audited_hash_json,
            presence: true

  def self.editable_in_console?
    false
  end
end
