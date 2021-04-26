# frozen_string_literal: true

class Folio::Devise::FlashCell < Folio::Devise::ApplicationCell
  def show
    render if model.present?
  end

  def application_module
    ::Rails.application.class.name.deconstantize
  end
end
