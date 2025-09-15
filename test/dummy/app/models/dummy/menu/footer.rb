# frozen_string_literal: true

class Dummy::Menu::Footer < Folio::Menu
  include Dummy::Menu::Base
  include Folio::Singleton

  def self.max_nesting_depth
    1
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
#  title      :string
#  site_id    :integer
#
# Indexes
#
#  index_folio_menus_on_site_id  (site_id)
#  index_folio_menus_on_type     (type)
#
