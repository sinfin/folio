# frozen_string_literal: true

class Dummy::Menu::Nestable < Folio::Menu
  def self.max_nesting_depth
    3
  end
end

# == Schema Information
#
# Table name: folio_menus
#
#  id         :bigint(8)        not null, primary key
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  locale     :string
#  title      :string
#
# Indexes
#
#  index_folio_menus_on_type  (type)
#
