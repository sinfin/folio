# frozen_string_literal: true

module Folio
  module HasAtoms
    extend ActiveSupport::Concern

    included do
      has_many :atoms, -> { order(:position) }, class_name: 'Folio::Atom', dependent: :destroy
      
      accepts_nested_attributes_for :atoms, reject_if: :all_blank, allow_destroy: true
    end
  end
end
