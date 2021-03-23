# frozen_string_literal: true

class Dummy::Ui::NavigationCell < ApplicationCell
  include Folio::ActiveClass
  include Folio::CstypoHelper

  def menu_items
    @menu_items ||= model.menu_items.includes(:page).arrange
  end

  def active_menu_item
    @active_menu_item ||= begin
      active = nil

      menu_items.each do |menu_item, children|
        next if active

        if children.present?
          children.each do |child, _x|
            next if active
            active ||= active_class(menu_url_for(child)) ? child : nil
          end
        else
          active ||= active_class(menu_url_for(menu_item)) ? menu_item : nil
        end
      end

      active
    end
  end
end
