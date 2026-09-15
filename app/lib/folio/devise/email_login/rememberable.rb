# frozen_string_literal: true

require "devise/strategies/rememberable"

class Folio::Devise::EmailLogin::Rememberable < Devise::Strategies::Rememberable
  include Folio::Devise::EmailLogin::StrategyVerification

  def valid?
    if Folio::Devise::EmailLogin.verification_enabled?
      return false if request.path_parameters[:controller].to_s.end_with?("/email_logins")
      return false if request.path_parameters[:controller].to_s.end_with?("/sessions") && request.path_parameters[:action] == "create"

      pending = Folio::Devise::EmailLogin::RequestSession.new(request)
      return false if %w[waiting approved].include?(pending.state)
    end

    super
  end

  private
    def email_login_purpose
      "rememberable"
    end
end
