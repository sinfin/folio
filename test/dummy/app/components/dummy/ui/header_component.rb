# frozen_string_literal: true

class Dummy::Ui::HeaderComponent < ApplicationComponent
  MENU_INPUT_ID = "d-ui-header__menu-input"

  def initialize
  end

  def menu
    @menu ||= current_header_menu
  end

  def data
    stimulus_controller("d-ui-header")
  end
end
