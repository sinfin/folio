# frozen_string_literal: true

module Folio
  class Console::AccountsController < Console::BaseController
    load_and_authorize_resource :account, class: 'Folio::Account'
    add_breadcrumb Account.model_name.human(count: 2), :console_accounts_path

    def index
      @accounts = @accounts.filter_by_params(filter_params)
                           .page(current_page)
      respond_with @accounts
    end

    def new
      @account = Account.new
    end

    def create
      @account = Account.create(account_params)
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
end
