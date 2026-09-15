# frozen_string_literal: true

class Folio::Users::EmailLogin::RevokeTrustComponent < Folio::ApplicationComponent
  def initialize; end

  def render?
    Folio::Devise::EmailLogin.enabled?
  end
end
