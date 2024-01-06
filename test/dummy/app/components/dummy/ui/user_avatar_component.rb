# frozen_string_literal: true

class Dummy::Ui::UserAvatarComponent < ApplicationComponent
  def initialize(not_link: false)
    @not_link = not_link
  end

  def data
    stimulus_controller("d-ui-user-avatar", action: {
      click: :clicked,
      "keydown.enter": :clicked,
      "keydown.esc": :clicked,
      "d-ui-menu-toolbar-dropdown:closed@window": "dropdownClosed",
    })
  end
end
