# frozen_string_literal: true

module Folio
  class Lead < ApplicationRecord
    # Validations
    validates_format_of :email, with: /[^@]+@[^@]+/ # modified devise regex
    validates :email, :note, presence: true

    # Scopes
    default_scope { order(created_at: :desc) }
    scope :by_query, -> (q) {
      if q.present?
        args = ["%#{q}%"] * 2
        where('email ILIKE ? OR note ILIKE ?', *args)
      else
        where(nil)
      end
    }

    def title
      email
    end
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
#  name       :string
#  url        :string
#
