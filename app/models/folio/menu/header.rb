# frozen_string_literal: true

module Folio
  class Menu::Header < Folio::Menu
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
#
# Indexes
#
#  index_folio_menus_on_type  (type)
#
