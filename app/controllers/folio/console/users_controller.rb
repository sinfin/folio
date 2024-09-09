# frozen_string_literal: true

class Folio::Console::UsersController < Folio::Console::BaseController
  folio_console_controller_for "Folio::User",
                               csv: true,
                               catalogue_collection_actions: %i[destroy csv]

  before_action :skip_email_reconfirmation, only: [:update]

  def index
    if params[:by_locked].blank?
      @users = @users.unlocked_for(Folio::Current.site)
    end

    super
  end

  def send_reset_password_email
    @user.send_reset_password_instructions
    redirect_back fallback_location: url_for([:console, @user]),
                  flash: { success: t(".success") }
  end

  def impersonate
    authorize! :impersonate, @user

    @user.sign_out_everywhere! if @user == current_user
    session[:true_user_id] = current_user.id
    bypass_sign_in @user, scope: :user

    redirect_to after_impersonate_path,
                allow_other_host: true,
                flash: { success: t(".success", label: @user.to_label) }
  end

  def stop_impersonating
    user = current_user
    bypass_sign_in true_user, scope: :user
    session[:true_user_id] = nil
    redirect_to url_for([:console, user])
  end

  def new
    @user.creating_in_console = 1
    @user.time_zone = Time.zone.name
  end

  def create
    create_params = user_params.merge(skip_password_validation: 1,
                                      creating_in_console: 1)
    @user = @klass.new(create_params)

    if @user.valid?
      @user = @klass.invite!(create_params, current_user)
    end

    respond_with @user, location: respond_with_location
  end

  def invite_and_copy
    if @user.invitation_created_at && !@user.invitation_accepted_at
      @user.invite!
      render json: { data: cell("folio/console/users/invite_and_copy", @user).show }
    else
      head 422
    end
  end

  private
    def after_impersonate_path
      Rails.application.config.folio_users_after_impersonate_path_proc.call(self, @user)
    end

    def user_params
      params.require(:user)
            .permit(*(@klass.column_names - user_params_blacklist),
                    :locked,
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
        by_locked: {
          as: :hidden,
        },
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
      }.merge(role_filters).merge(auth_site_filters)
    end

    def index_filters
      default_index_filters
    end

    def role_filters
      allowed_roles = current_site.available_user_roles_ary.select do |role|
        can_now?("read_#{role}s", nil)
      end

      roles = @klass.roles_for_select(site: current_site,
                                      selectable_roles: allowed_roles)
      roles.unshift(["Superadmin", "superadmin"]) if can_now?(:manage, :all)

      roles.size > 1 ? { by_role: roles } : {}
    end

    def auth_site_filters
      return {} unless current_user.superadmin?

      sites_for_select = Folio::Site.pluck(:title, :id)
      sites_for_select.size > 1 ? { by_auth_site: sites_for_select } : {}
    end

    def folio_console_collection_includes
      []
    end

    def folio_console_record_includes
      []
    end

    def site_user_links_params
      [ site_user_links_attributes: [:site_id, :locked, roles: []] ]
    end

    def additional_user_params
      []
    end

    def skip_email_reconfirmation
      @user.skip_reconfirmation! if Rails.application.config.folio_users_confirm_email_change
    end

    def index_tabs
      user_locking_tabs
    end

    def user_locking_tabs
      accesible_users = Folio::User.accessible_by(::Folio::Current.ability)
      locked_users = accesible_users.where(id: locked_user_ids_subselect)
      unlocked_users = accesible_users.where.not(id: locked_user_ids_subselect)

      [
        {
          label: t(".index_tabs/unlocked"),
          force_href: url_for([:console, @klass, by_locked: "false"]),
          count: unlocked_users.count || 0,
          active: active_tab == :unlocked,
        },
        {
          label: t(".index_tabs/locked"),
          force_href: url_for([:console, @klass, by_locked: "true"]),
          count: locked_users.count || 0,
          active: active_tab == :locked,
        }
      ]
    end

    def active_tab
      if params.key?(:by_locked)
        params[:by_locked] == "true" ? :locked : :unlocked
      else
        :unlocked
      end
    end

    def locked_user_ids_subselect
      @locked_user_ids_subselect ||= Folio::SiteUserLink.by_site(Folio::Current.site)
                                                        .locked
                                                        .select(:user_id)
    end
end
