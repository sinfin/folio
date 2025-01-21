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
end

# == Schema Information
#
# Table name: folio_atoms
#
#  id             :bigint(8)        not null, primary key
#  type           :string
#  position       :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  placement_type :string
#  placement_id   :bigint(8)
#  locale         :string
#  data           :jsonb
#  associations   :jsonb
#
# Indexes
#
#  index_folio_atoms_on_placement_type_and_placement_id  (placement_type,placement_id)
#
