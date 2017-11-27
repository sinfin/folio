# frozen_string_literal: true

module Folio
  class NewsletterSubscription < ApplicationRecord
    include Filterable


    # Validations
    validates_format_of :email,
                        with: /[^@]+@[^@]+/ # modified devise regex

    # Scopes
    scope :by_query, -> (q) {
        if q.present?
          where('email ILIKE ?', "%#{q}%")
          # search_node(args)
        else
          where(nil)
        end
      }

    def title
      email
    end
  end
end
