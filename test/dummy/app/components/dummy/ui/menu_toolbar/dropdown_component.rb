# frozen_string_literal: true

class Dummy::Ui::MenuToolbar::DropdownComponent < ApplicationComponent
  def initialize(type: nil, title: nil, items: nil, signed_in: nil, trigger: nil, width: 200)
    @type = type
    @title = title
    @items = items
    @signed_in = signed_in
    @trigger = trigger
    @width = width
  end

  def dropdown_title
    if @title.nil?
      if @type == :user_menu && @signed_in
        { title: "Username", user_name: true }
      elsif @type == :user_menu && !@signed_in
        { title: "Login", icon: :user }
      elsif @type == :eshop_menu
        { title: "Shop", icon: :shopping_cart }
      end
    else
      @title
    end
  end

  def items
    if @items.nil?
      if @type == :user_menu && @signed_in
        [
          { label: "User profile" },
          { label: "Other item" },
          { label: "Other item" },
          { label: "Logout", icon: :upload, icon_height: 16, class_modifier: "logout" },
        ]
      elsif @type == :user_menu && !@signed_in
        [
          { label: "Registrate" },
          { label: "Login" },
        ]
      elsif @type == :eshop_menu
        [
          { label: "Shoping cart", shopped_items_count: true },
          { label: "Wishlist", disabled: true },
          { label: "Help" },
        ]
      end
    else
      @items
    end
  end

  def dropdown_trigger
    if @trigger.nil?
      if @type == :user_menu
        "d-ui-user-avatar"
      elsif @type == :eshop_menu
        "d-ui-menu-toolbar-shopping-cart"
      else
        "unknown-dropdown-trigger"
      end
    else
      @trigger
    end
  end

  def data
    stimulus_controller("d-ui-menu-toolbar-dropdown", values: {
      width: @width,
      dropdown_trigger:,
    }, action: {
      "#{dropdown_trigger}:clicked@window": "triggerClicked",
      "resize@window": "setPosition",
      "orientationchange@window": "setPosition"
    })
  end
end
