# frozen_string_literal: true

class Dummy::Ui::HeaderCell < ApplicationCell
  MENU_INPUT_ID = "d-ui-header__menu-input"

  def menu
    @menu ||= Dummy::Menu::Header.instance(fail_on_missing: false)
  end
end
