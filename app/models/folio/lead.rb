module Folio
  class Lead < ApplicationRecord
    validates_format_of :email, with: /[^@]+@[^@]+/ # modified devise regex
  end
end

# == Schema Information
#
# Table name: folio_leads
#
#  id         :integer          not null, primary key
#  email      :string
#  phone      :string
#  note       :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
