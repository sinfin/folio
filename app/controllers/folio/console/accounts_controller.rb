# frozen_string_literal: true

class Folio::Console::AccountsController < Folio::Console::BaseController
  folio_console_controller_for 'Folio::Account'

  def index
    @pagy, @accounts = pagy(@accounts)
  end

  def create
    @account = Folio::Account.create(account_params)
    respond_with @account
  end

  def update
    @account.update(account_params)
    respond_with @account
  end

  def destroy
    @account.destroy
    respond_with @account
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
