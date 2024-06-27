# frozen_string_literal: true

class Dummy::CurrentUserController < ApplicationController
  def settings
    @user = current_user
  end

  def update_settings
    current_user.update(user_params)
  end

  private
    def user_params
      params.require(:user).permit(:time_zone)
    end
end
