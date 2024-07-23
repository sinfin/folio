# frozen_string_literal: true

class Dummy::Atom::Divider < Folio::Atom::Base
  ATTACHMENTS = %i[]

  STRUCTURE = {
    variant: %w[default thin thick invisible],
    margin: %w[small medium large extra-large],

  }

  ASSOCIATIONS = {}

  after_initialize do
    self.variant ||= self.class.default_atom_values[:variant]
    self.margin ||= self.class.default_atom_values[:margin]
  end

  def variant_with_fallback
    variant.presence || self.class.default_atom_values[:variant]
  end

  def margin_with_fallback
    margin.presence || self.class.default_atom_values[:margin]
  end

  def self.default_atom_values
    {
      variant: "default",
      margin: "medium",
    }
  end

  def self.console_insert_row
    0
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
