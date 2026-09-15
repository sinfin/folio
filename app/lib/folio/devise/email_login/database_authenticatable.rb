# frozen_string_literal: true

require "devise/strategies/database_authenticatable"

class Folio::Devise::EmailLogin::DatabaseAuthenticatable < Devise::Strategies::DatabaseAuthenticatable
  include Folio::Devise::EmailLogin::StrategyVerification

  private
    def email_login_purpose
      "password"
    end
end
