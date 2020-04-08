# frozen_string_literal: true

module Folio::ReferencedFromMenuItems
  extend ActiveSupport::Concern

  included do
    has_many :menu_items, class_name: 'Folio::MenuItem',
                          as: :target,
                          dependent: :destroy

    after_update :destroy_menu_items_if_unpublished
  end

  private
    def destroy_menu_items_if_unpublished
      if try(:published?) == false && menu_items.present?
        menu_items.destroy_all
      end
    end
end
