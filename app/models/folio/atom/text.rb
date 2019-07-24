# frozen_string_literal: true

class Folio::Atom::Text < Folio::Atom::Base
  STRUCTURE = {
    content: :richtext,
  }

  validates :content,
            presence: true

  def self.cell_name
    'folio/atom/text'
  end
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
#  model_type     :string
#  locale         :string
#  data           :jsonb
#
# Indexes
#
#  index_folio_atoms_on_placement_type_and_placement_id  (placement_type,placement_id)
#
