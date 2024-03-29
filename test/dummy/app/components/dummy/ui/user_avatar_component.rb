# frozen_string_literal: true

class Dummy::Ui::UserAvatarComponent < ApplicationComponent
  def initialize(link: true, current_user_for_test: nil)
    @link = link
    @current_user_for_test = current_user_for_test
  end

  def data
    if @link
      stimulus_controller("d-ui-user-avatar", action: {
        click: :clicked,
        "keydown.enter": "clicked",
        "keydown.esc": "clicked",
        "d-ui-menu-toolbar-dropdown:closed@window": "dropdownClosed",
      })
    end
  end

  def user_class_name
    unless current_user_with_test_fallback
      "d-ui-user-avatar--signed-out"
    end
  end

  def link_class_name
    unless @link
      "d-ui-user-avatar--not-link"
    end
  end

  def letters
    if current_user_with_test_fallback
      if current_user_with_test_fallback.full_name.present?
        return current_user_with_test_fallback.full_name.split(/\s+/).map(&:first).first(2).join("").upcase
      elsif current_user_with_test_fallback.email.present?
        return current_user_with_test_fallback.email.split("@").map(&:first).first(2).join("").upcase
      end
    end

    "XX"
  end
end
