# frozen_string_literal: true

class Dummy::Menu::Header < Folio::Menu
  include Folio::Singleton

  def self.max_nesting_depth
    2
  end
end

# == Schema Information
#
# Table name: folio_menus
#
#  id         :bigint(8)        not null, primary key
#  locale     :string
#  title      :string
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_folio_menus_on_type  (type)
#
