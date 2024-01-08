# frozen_string_literal: true

class Dummy::Ui::MenuToolbar::DropdownComponent < ApplicationComponent
  def initialize(type: nil, title: nil, items: nil, signed_in: nil, trigger: nil, width: 200, current_user_for_test: nil)
    @type = type
    @title = title
    @items = items
    @signed_in = signed_in
    @trigger = trigger
    @width = width
    @current_user_for_test = current_user_for_test
  end

  def dropdown_title
    if @title.nil?
      if @type == :user_menu
        if current_user_with_test_fallback
          { username: current_user_with_test_fallback.to_label }
        else
          { title: t(".user_menu/title"), icon: :user }
        end
      elsif @type == :eshop_menu
        { title: t(".eshop_menu/title"), icon: :shopping_cart }
      end
    else
      @title
    end
  end

  def items
    return @items if @items.present?

    if @type == :user_menu
      @items = if current_user_with_test_fallback
        [
          {
            label: t(".user_menu/sign_out"),
            icon: :log_out,
            icon_height: 16,
            class_modifier: "logout",
            href: controller.main_app.try(:destroy_user_session_path),
          },
        ]
      else
        [
          {
            label: t(".user_menu/sign_in"),
            href: controller.main_app.new_user_session_path,
            data: stimulus_modal_toggle(Folio::Devise::ModalCell::CLASS_NAME, dialog: ".f-devise-modal__dialog--sessions")
          },
          {
            label: t(".user_menu/sign_up"),
            href: controller.main_app.new_user_invitation_path,
            data: stimulus_modal_toggle(Folio::Devise::ModalCell::CLASS_NAME, dialog: ".f-devise-modal__dialog--registrations")
          },
        ]
      end
    elsif @type == :eshop_menu
      @items = [
        { label: "Shoping cart", shopped_items_count: true },
        { label: "Disabled item", disabled: true },
        { label: "Wishlist", wish_items_count: true },
        { label: "Help" },
      ]
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
      "orientationchange@window": "setPosition",
      "keydown.esc": "close",
    })
  end
end
