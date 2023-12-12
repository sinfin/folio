# frozen_string_literal: true

class Folio::UiController < Folio::BaseController
  before_action :authenticate_account!

  def ui
  end

  def mobile_typo
    @mobile_typo = true
    render :ui
  end
end
