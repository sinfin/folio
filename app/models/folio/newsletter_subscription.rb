# frozen_string_literal: true

module Folio
  class NewsletterSubscription < ApplicationRecord
    include Filterable


    # Validations
    validates_format_of :email,
                        with: /[^@]+@[^@]+/ # modified devise regex

    # Scopes
    default_scope { order(created_at: :desc) }
    scope :by_query, -> (q) {
      if q.present?
        where('email ILIKE ?', "%#{q}%")
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
# Table name: folio_newsletter_subscriptions
#
#  id         :integer          not null, primary key
#  email      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
