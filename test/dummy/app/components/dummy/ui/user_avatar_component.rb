# frozen_string_literal: true

class Dummy::Ui::UserAvatarComponent < ApplicationComponent
  def initialize
  end

  def data
    stimulus_controller("d-ui-user-avatar")
  end
end
