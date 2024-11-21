# frozen_string_literal: true

class Dummy::CurrentUserController < ApplicationController
  def settings
    @user = Folio::Current.user
  end

  def update_settings
    Folio::Current.user.update(user_params)
  end

  private
    def user_params
      params.require(:user).permit(:time_zone)
    end
end
