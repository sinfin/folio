# frozen_string_literal: true

class Folio::Console::AccountsController < Folio::Console::BaseController
  load_and_authorize_resource :account, class: 'Folio::Account'
  add_breadcrumb Folio::Account.model_name.human(count: 2), :console_accounts_path

  def index
    @pagy, @accounts = pagy(@accounts.filter_by_params(filter_params))
    respond_with @accounts
  end

  def new
    @account = Folio::Account.new
  end

  def create
    @account = Folio::Account.create(account_params)
    respond_with @account, location: console_accounts_path
  end

  def update
    @account.update(account_params)
    respond_with @account, location: console_accounts_path
  end

  def destroy
    @account.destroy
    respond_with @account, location: console_accounts_path
  end

  private

    def filter_params
      params.permit(:by_is_active, :by_query)
    end

    def account_params
      p = params.require(:account).permit(:role, :email, :first_name, :last_name, :password, :is_active)
      p.delete(:password) unless p[:password].present?
      p
    end
end
