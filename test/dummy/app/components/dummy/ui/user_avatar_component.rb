# frozen_string_literal: true

class Dummy::Ui::UserAvatarComponent < ApplicationComponent
  def initialize
  end

  def data
    stimulus_controller("d-ui-user-avatar", action: {
      click: :clicked,
      "d-ui-menu-toolbar-dropdown:closed@window": "dropdownClosed",
    })
  end
end
