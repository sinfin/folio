# frozen_string_literal: true

class Folio::ImpersonatingHeaderCell < Folio::ApplicationCell
  def show
    render if impersonating_in_progress?
  end

  def impersonating_in_progress?
    current_user != true_user
  end

  def true_user
    controller.true_user
  end
end
