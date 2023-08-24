# frozen_string_literal: true

class Dummy::Ui::HeaderComponent < ApplicationComponent
  MENU_INPUT_ID = "d-ui-header__menu-input"

  def menu
    @menu ||= current_header_menu
  end
end