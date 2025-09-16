# frozen_string_literal: true

module Folio::ApplicationControllerBase
  extend ActiveSupport::Concern

  include Folio::Devise::CrossdomainController
  include Folio::RenderComponentJson
  include Folio::SetCurrentRequestDetails
  include Folio::SetMetaVariables
  include Folio::HttpCache::Headers

  included do
    include Pagy::Backend

    protect_from_forgery with: :exception

    layout :current_site_based_layout

    before_action :set_i18n_locale

    before_action :set_cookies_for_log

    before_action :add_root_breadcrumb

    around_action :set_time_zone, if: -> { Folio::Current.user }

    add_flash_types :success, :warning, :info

    rescue_from CanCan::AccessDenied, with: :handle_can_can_access_denied

    # Apply basic HTTP cache headers after each action when enabled
    after_action :set_cache_control_headers
  end

  def set_i18n_locale
    if params[:locale] && Folio::Current.site.locales.include?(params[:locale])
      I18n.locale = params[:locale]
    else
      I18n.locale = Folio::Current.site.locale
    end
  end

  def default_url_options
    { only_path: true }
  end

  def url_for(options = nil)
    if Rails.application.config.folio_pages_ancestry &&
       options &&
       options.is_a?(Folio::Page)
      nested_page_path(options)
    else
      super(options)
    end
  end

  def can_now?(action, object = nil)
    object ||= Folio::Current.site
    (Folio::Current.user || Folio::User.new).can_now_by_ability?(::Folio::Current.ability, action, object)
  end

  def true_user
    if session[:true_user_id].present?
      Folio::User.find_by(id: session[:true_user_id])
    else
      Folio::Current.user
    end
  end

  private
    def authenticate_account! # backward compatibility method, do not use
      authenticate_user!
      can_now?(:access_console) || raise(CanCan::AccessDenied)
    end

    def nested_page_path(page)
      return nil unless main_app.respond_to?(:page_path)
      main_app.page_path(path: page.ancestry_url)
    end

    def force_correct_path(correct_path_or_url, ignore_get_params: true, status: :moved_permanently)
      # If an old id or a numeric id was used to find the record, then
      # the request path will not match the post_path, and we should do
      # a 301 redirect that uses the current friendly id.
      if ignore_get_params && request.path != correct_path_or_url && request.url.split("?")[0] != correct_path_or_url.split("?")[0]
        redirect_to(correct_path_or_url, status:, allow_other_host: true)
        true
      elsif !ignore_get_params && request.fullpath != correct_path_or_url && request.url != correct_path_or_url
        redirect_to(correct_path_or_url, status:, allow_other_host: true)
        true
      else
        false
      end
    end

    def atom_includes
      [
        atoms: {
          cover_placement: :file,
          document_placement: :file,
          image_placements: :file,
          document_placements: :file,
        }
      ]
    end

    def set_cookies_for_log
      # Skip log cookies for cache-friendly anonymous requests (prevents Cloudflare BYPASS)
      if should_skip_cookies_for_cache?
        return
      end

      if session_id = session.id.try(:public_id)
        cookies.signed[:s_for_log] = session_id unless cookies.signed[:s_for_log] == session_id
      else
        cookies.signed[:s_for_log] = nil if cookies.signed[:s_for_log]
      end

      catch(:warden) do
        if user_id = Folio::Current.user.try(:id)
          cookies.signed[:u_for_log] = user_id unless cookies.signed[:u_for_log] == user_id
        else
          cookies.signed[:u_for_log] = nil if cookies.signed[:u_for_log]
        end
      end
    end

    def should_skip_cookies_for_cache?
      # Skip cookies if cache optimization is enabled and this is a cache-friendly request
      return false unless Rails.application.config.respond_to?(:folio_cache_skip_session_for_public) &&
                          Rails.application.config.folio_cache_skip_session_for_public

      # Same logic as in cache headers - only skip for anonymous GET requests to non-admin paths
      request.get? &&
        !Folio::Current.user.present? &&
        !controller_path.include?("console") &&
        !controller_path.include?("admin") &&
        !controller_path.include?("api")
      end

    def current_site_based_layout
      Folio::Current.site ? Folio::Current.site.layout_name : "folio/application"
    end

    def authenticate_inviter!
      # allow anonymous invites
    end

    def current_ability # so CanCanCan can use it
      @current_ability ||= ::Folio::Current.ability
    end

    def set_time_zone(&block)
      Time.use_zone(Folio::Current.user.time_zone, &block)
    end

    def add_root_breadcrumb
      add_breadcrumb_on_rails(t("folio.root_breadcrumb"), "/")
    end

    def handle_can_can_access_denied(e)
      if Rails.application.config.consider_all_requests_local
        raise e
      end

      Raven.capture_exception(e) if defined?(Raven)
      Sentry.capture_exception(e) if defined?(Sentry)

      if request.path.starts_with?("/console") && !can_now?(:access_console)
        redirect_to "/403"
      else
        @error_code = 403
        render "folio/errors/show", status: @error_code
      end
    end
end
