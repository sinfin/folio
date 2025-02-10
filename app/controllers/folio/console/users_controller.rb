# frozen_string_literal: true

class Folio::Console::UsersController < Folio::Console::BaseController
  folio_console_controller_for "Folio::User",
                               csv: true,
                               catalogue_collection_actions: %i[destroy csv]

  before_action :skip_email_reconfirmation, only: [:update]

  def send_reset_password_email
    if Rails.application.config.folio_users_publicly_invitable && !@user.accepted_or_not_invited?
      @user.invite!(current_account)
      message = t(".success.invite_again")
    else
      @user.send_reset_password_instructions
      message = t(".success.reset_password")
    end

    redirect_back fallback_location: url_for([:console, @user]),
                  flash: { success: message }
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
            .permit(*(@klass.column_names - user_params_blacklist),
                    *addresses_strong_params,
                    *file_placements_strong_params,
                    *private_attachments_strong_params,
                    *additional_user_params)
    end

    def user_params_blacklist
      ["id"]
    end

    def default_index_filters
      {
        by_full_name_query: {
          as: :text,
          autocomplete_attribute: :last_name,
        },
        by_addresses_query: {
          as: :text,
        },
        by_address_identification_number_query: {
          as: :text,
          autocomplete_attribute: :identification_number,
          autocomplete_klass: Folio::Address::Base,
        },
        by_email_query: {
          as: :text,
          autocomplete_attribute: :email,
        },
      }
    end

    def index_filters
      default_index_filters
    end

    def folio_console_collection_includes
      []
    end

    def folio_console_record_includes
      []
    end

    def additional_user_params
      []
    end

    def skip_email_reconfirmation
      @user.skip_reconfirmation! if Rails.application.config.folio_users_confirm_email_change
    end
end
