# frozen_string_literal: true

class Folio::Console::UsersController < Folio::Console::BaseController
  folio_console_controller_for "Folio::User",
                               csv: true,
                               catalogue_collection_actions: %i[destroy csv]

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

  def new
    @user.creating_in_console = 1
  end

  def create
    create_params = user_params.merge(skip_password_validation: 1,
                                      creating_in_console: 1)

    @user = @klass.new(create_params)

    if @user.valid?
      @user = @klass.invite!(create_params)
    end

    respond_with @user, location: respond_with_location
  end

  private
    def after_impersonate_path
      main_app.send(Rails.application.config.folio_users_after_impersonate_path)
    end

    def user_params
      params.require(:user)
            .permit(*(@klass.column_names - ["id"]),
                    *addresses_strong_params,
                    *file_placements_strong_params,
                    *private_attachments_strong_params)
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
