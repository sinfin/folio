# frozen_string_literal: true

class Dummy::Menu::Navigation < Folio::Menu
  include Dummy::Menu::Base

  def self.max_nesting_depth
    1
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
