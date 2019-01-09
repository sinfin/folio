# frozen_string_literal: true

module Folio::ReferencedFromAtoms
  extend ActiveSupport::Concern

  included do
    has_many :atoms, class_name: 'Folio::Atom::Base',
                     as: :model,
                     dependent: :destroy
  end
end
