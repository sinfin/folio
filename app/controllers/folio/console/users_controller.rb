# frozen_string_literal: true

class Folio::Console::UsersController < Folio::Console::BaseController
  folio_console_controller_for "Folio::User"

  def send_reset_password_email
    @user.send_reset_password_instructions
    redirect_back fallback_location: url_for([:console, @user]),
                  flash: { success: t(".success") }
  end

  def impersonate
    bypass_sign_in @user, scope: :user
    redirect_to after_impersonate_path,
                flash: { success: t(".success", label: @user.to_label) }
  end

  def create
    @user = @klass.invite!(user_params)
    respond_with @user, location: respond_with_location
  end

  private
    def after_impersonate_path
      main_app.root_path
    end

    def user_params
      params.require(:user)
            .permit(:email)
    end

    def index_filters
      {}
    end

    def folio_console_collection_includes
      []
    end

    def folio_console_record_includes
      []
    end
end
