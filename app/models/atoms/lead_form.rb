class Atoms::LeadForm < Folio::Atom
  def cell_name
    'folio/lead_form'
  end
end

# == Schema Information
#
# Table name: folio_atoms
#
#  id         :integer          not null, primary key
#  type       :string
#  node_id    :integer
#  content    :text
#  position   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_folio_atoms_on_node_id  (node_id)
#
