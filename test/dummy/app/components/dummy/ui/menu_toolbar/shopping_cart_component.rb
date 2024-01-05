# frozen_string_literal: true

class Dummy::Ui::MenuToolbar::ShoppingCartComponent < ApplicationComponent
  def initialize
  end

  def data
    stimulus_controller("d-ui-menu-toolbar-shopping-cart", action: {
      "d-ui-menu-toolbar-dropdown:closed@window": "dropdownClosed",
    })
  end
end
