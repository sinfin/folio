# frozen_string_literal: true

class Dummy::Atom::Forms::Leads::Form < Folio::Atom::Base
  ATTACHMENTS = %i[]

  STRUCTURE = {
    title: :string,
  }

  ASSOCIATIONS = {}

  def self.console_insert_row
    CONSOLE_INSERT_ROWS[:forms]
  end
end

# == Schema Information
#
# Table name: folio_atoms
#
#  id              :bigint(8)        not null, primary key
#  type            :string
#  position        :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  placement_type  :string
#  placement_id    :bigint(8)
#  locale          :string
#  data            :jsonb
#  associations    :jsonb
#
# Indexes
#
#  index_folio_atoms_on_placement_type_and_placement_id  (placement_type,placement_id)
#