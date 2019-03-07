# frozen_string_literal: true

class Folio::Console::AccountsController < Folio::Console::BaseController
  folio_console_controller_for 'Folio::Account'

  def index
    @pagy, @accounts = pagy(@accounts)
  end

  private

    def account_params
      p = params.require(:account)
                .permit(:role,
                        :email,
                        :first_name,
                        :last_name,
                        :password,
                        :is_active)
      p.delete(:password) unless p[:password].present?
      p
    end
end
