# frozen_string_literal: true

class Folio::Users::InvitationsController < Devise::InvitationsController
  include Folio::Users::DeviseControllerBase
  include Folio::HasTurnstileValidation

  prepend_before_action :require_no_authentication, only: %i[create new]
  before_action :disallow_public_invitations_if_needed, only: %i[create new]

  def new
    if Rails.application.config.folio_crossdomain_devise && current_site != ::Folio.enabled_site_for_crossdomain_devise
      session[Folio::Devise::CrossdomainHandler::SESSION_KEY] ||= {}
      session[Folio::Devise::CrossdomainHandler::SESSION_KEY][:target_site_slug] = current_site.slug

      redirect_to new_user_invitation_url(only_path: false,
                                          host: ::Folio.enabled_site_for_crossdomain_devise.env_aware_domain),
                  allow_other_host: true
    else
      super
    end
  end

  def show
    if session[:folio_user_invited_email]
      @email = session[:folio_user_invited_email]
    else
      redirect_to new_user_invitation_path
    end
  end

  def create
    self.resource = invite_resource
    resource_invited = resource.errors.empty?

    if source_site_for_user.present? && resource_invited
      resource.update_column(:source_site_id, source_site_for_user.id)
      resource.create_site_links_for([current_site, source_site_for_user])
    end


    respond_to do |format|
      # need to override devise invitable here with devise default
      format.html do
        yield resource if block_given?

        if resource_invited
          if is_flashing_format? && self.resource.invitation_sent_at
            set_flash_message :notice, :send_instructions, email: self.resource.email
          end
          if self.method(:after_invite_path_for).arity == 1
            respond_with resource, location: after_invite_path_for(current_inviter)
          else
            respond_with resource, location: after_invite_path_for(current_inviter, resource)
          end
        else
          respond_with_navigational(resource) { render :new, status: :unprocessable_entity }
        end
      end
      # custom for JSON api
      format.json do
        @force_flash = true

        if resource_invited
          if is_flashing_format? && self.resource.invitation_sent_at
            set_flash_message :notice, :send_instructions, email: self.resource.email
          end

          if Rails.application.config.folio_users_after_ajax_sign_up_redirect
            json = {
              data: {
                url: stored_location_for(:user).presence || after_invite_path_for(current_inviter, resource),
              }
            }
          else
            if request.referrer
              if params[:modal_non_get_request].blank?
                store_location_for(:user, request.referrer)
              elsif path = Rails.application.config.folio_users_non_get_referrer_rewrite_proc.call(request.referrer)
                store_location_for(:user, path)
              else
                # remove stored
                stored_location_for(:user)
              end
            else
              # remove stored
              stored_location_for(:user)
            end

            json = {
              data: {
                url: after_invite_path_for(current_inviter, resource),
              }
            }
          end

          render json:, status: 200
        else
          message = t("folio.users.invitations.create.failure")

          errors = [{ status: 401, title: "Unauthorized", detail: message }]
          cell_flash = ActionDispatch::Flash::FlashHash.new
          cell_flash[:alert] = message

          html = cell("folio/devise/invitations/new",
                      resource:,
                      resource_name: :user,
                      modal: true,
                      flash: cell_flash,
                      modal_non_get_request: params[:modal_non_get_request].present?).show

          render json: { errors:, data: html }, status: 401
        end
      end
    end
  end

  def after_invite_path_for(_inviter, resource)
    session[:folio_user_invited_email] = resource.email
    user_invitation_path
  end

  private
    def update_resource_params
      h = params.require(:user)
                .permit(*Folio::User.controller_strong_params_for_create)
                .to_h
      super.merge(h)
    end

    def disallow_public_invitations_if_needed
      return if Rails.application.config.folio_users_publicly_invitable
      fail "Not allowed to publicly invite."
    end

    def source_site_for_user
      if site_slug = session&.dig(Folio::Devise::CrossdomainHandler::SESSION_KEY, :target_site_slug)
        return Folio::Site.find(site_slug)
      end

      current_site
    end

    def require_no_authentication
      safe_set_up_current_from_request

      super

      if resource.nil? && current_user
        set_flash_message(:alert, "already_authenticated", scope: "devise.failure")
        redirect_to after_sign_in_path_for(current_user)
      end
    end

    def turnstile_failure_redirect_path
      new_user_invitation_path
    end
end
