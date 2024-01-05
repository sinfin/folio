# frozen_string_literal: true

class Folio::UiController < Folio::BaseController
  before_action :authenticate_user!
  before_action :authorize_user!

  def ui
  end

  def mobile_typo
    @mobile_typo = true
    render :ui
  end

  def atoms
  end

  private
    def authorize_user!
      raise CanCan::AccessDenied unless can_now?(:display_ui)
    end
end
