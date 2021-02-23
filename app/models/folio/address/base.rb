# frozen_string_literal: true

class Folio::Address::Base < Folio::ApplicationRecord
  include Folio::StiPreload

  self.table_name = "folio_addresses"

  validates :city,
            :name,
            :address_line_1,
            :zip,
            :type,
            presence: true

  validates :country_code,
            presence: true,
            if: :should_validate_country_code?

  audited only: %i[city country_code name street zip]

  def country
    ISO3166::Country.new(country_code)
  end

  def to_label
    [address_line_1, address_line_2].map(&:presence).compact.join(", ")
  end

  def self.sti_paths
    [
      Folio::Engine.root.join("app/models/folio/address"),
      Rails.root.join("app/models/**/address"),
    ]
  end

  private
    def should_validate_country_code?
      true
    end
end

# == Schema Information
#
# Table name: folio_addresses
#
#  id                        :bigint(8)        not null, primary key
#  name                      :string
#  address_line_1            :string
#  address_line_2            :string
#  zip                       :string
#  city                      :string
#  country_code              :string
#  state                     :string
#  identification_number     :string
#  vat_identification_number :string
#  phone                     :string
#  email                     :string
#  type                      :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
# Indexes
#
#  index_folio_addresses_on_type  (type)
#
