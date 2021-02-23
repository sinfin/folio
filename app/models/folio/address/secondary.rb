# frozen_string_literal: true

class Folio::Address::Secondary < Folio::Address::Base
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
