# frozen_string_literal: true

class Folio::Console::AccountsController < Folio::Console::BaseController
  folio_console_controller_for "Folio::Account"

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

  def invite_and_copy
    if @account.invitation_created_at && !@account.invitation_accepted_at
      @account.invite!
      render json: { data: cell("folio/console/accounts/invite_and_copy", @account).show }
    else
      head 422
    end
  end

  private
    def account_params
      p = params.require(:account)
                .permit(:email,
                        :first_name,
                        :last_name,
                        :is_active,
                        :password,
                        *Folio::Account.additional_params,
                        roles: [])
      p.delete(:password) unless p[:password].present?

      roles = filter_account_params_roles(p.delete(:roles))
      p[:roles] = roles if roles.present?

      p
    end

    def filter_account_params_roles(roles)
      if roles.present?
        roles.select do |role|
          Folio::Account.roles.include?(role)
        end
      end
    end

    def index_filters
      roles = @klass.roles_for_select(current_account.account_roles_for_select)

      if roles.size > 1
        {
          by_role: roles
        }
      else
        {}
      end
    end
end
