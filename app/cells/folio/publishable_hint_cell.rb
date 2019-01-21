# frozen_string_literal: true

class Folio::PublishableHintCell < Folio::ApplicationCell
  def show
    render if visible_to_admins_only?
  end

  def visible_to_admins_only?
    !model.published? && controller.account_signed_in?
  end
end
