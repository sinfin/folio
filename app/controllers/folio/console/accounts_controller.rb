# frozen_string_literal: true

class Folio::Console::AccountsController < Folio::Console::BaseController
  folio_console_controller_for "Folio::Account"

  def index
    @pagy, @accounts = pagy(@accounts)
  end

  def create
    @account = Folio::Account.invite!(account_params)
    respond_with @account, location: respond_with_location
  end

  def update
    super

    if @account.saved_change_to_encrypted_password? && !@account.invitation_accepted_at
      @account.update(invitation_accepted_at: Time.current, invitation_token: nil)
    end
  end

  private
    def account_params
      p = params.require(:account)
                .permit(:role,
                        :email,
                        :first_name,
                        :last_name,
                        :is_active,
                        :password)
      p.delete(:password) unless p[:password].present?
      p
    end

    def index_filters
      {
        by_role: @klass.roles_for_select
      }
    end
end
