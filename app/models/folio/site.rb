# frozen_string_literal: true

module Folio
  class Site < ApplicationRecord
    # Relations
    has_many :nodes, class_name: 'Folio::Node'

    # Validations
    validates :title, presence: true
    validates :domain, uniqueness: true
  end
end
