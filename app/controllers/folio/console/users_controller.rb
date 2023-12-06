# frozen_string_literal: true

class Folio::Console::UsersController < Folio::Console::BaseController
  folio_console_controller_for "Folio::User",
                               csv: true,
                               catalogue_collection_actions: %i[destroy csv]

  before_action :skip_email_reconfirmation, only: [:update]

  def send_reset_password_email
    @user.send_reset_password_instructions
    redirect_back fallback_location: url_for([:console, @user]),
                  flash: { success: t(".success") }
  end

  def impersonate
    @user.sign_out_everywhere! if @user == current_user
    bypass_sign_in @user.reload, scope: :user
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
      @user = @klass.invite!(create_params, current_account)
    end

    respond_with @user, location: respond_with_location
  end

  private
    def after_impersonate_path
      Rails.application.config.folio_users_after_impersonate_path_proc.call(self, @user)
    end

    def user_params
      params.require(:user)
            .permit(*(@klass.column_names - user_params_blacklist),
                    *site_user_links_params,
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

    def site_user_links_params
      [ site_user_links_attributes: [:site_id, roles: []] ]
    end

    def additional_user_params
      []
    end

    def skip_email_reconfirmation
      @user.skip_reconfirmation! if Rails.application.config.folio_users_confirm_email_change
    end
end
