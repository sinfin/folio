# frozen_string_literal: true

module Folio
  class Menu < ApplicationRecord
    # Relations
    has_many :menu_items, dependent: :destroy
    accepts_nested_attributes_for :menu_items, allow_destroy: true,
                                               reject_if: :all_blank

    # Validations
    validates :type, :locale,
              presence: true

    alias_attribute :items, :menu_items

    def title
      type
    end

    def available_targets
      Folio::Node.where(locale: locale)
    end
  end
end

if Rails.env.development?
  Dir["#{Folio::Engine.root}/app/models/folio/menu/*.rb", 'app/models/menu/*.rb'].each do |file|
    require_dependency file
  end
end

# == Schema Information
#
# Table name: folio_menus
#
#  id         :integer          not null, primary key
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  locale     :string
#
# Indexes
#
#  index_folio_menus_on_type  (type)
#
