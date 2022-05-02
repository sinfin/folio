# frozen_string_literal: true

class Folio::Devise::Invitations::ShowCell < Folio::Devise::ApplicationCell
  def show
    render if model.present?
  end
end
