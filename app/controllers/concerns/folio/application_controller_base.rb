# frozen_string_literal: true

module Folio::ApplicationControllerBase
  extend ActiveSupport::Concern
  include Folio::SetMetaVariables
  include Folio::HasCurrentSite
  include Folio::Devise::CrossdomainController
  include Folio::RenderComponentJson

  included do
    include Pagy::Backend

    protect_from_forgery with: :exception

    layout :current_site_based_layout

    before_action :set_i18n_locale

    before_action :set_cookies_for_log

    helper_method :current_site

    add_flash_types :success, :warning, :info
  end

  def set_i18n_locale
    if params[:locale] && current_site.locales.include?(params[:locale])
      I18n.locale = params[:locale]
    else
      I18n.locale = current_site.locale
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
    object ||= current_site
    (current_user || Folio::User.new).can_now_by_ability?(current_ability, action, object)
  end

  def true_user
    if session[:true_user_id].present?
      Folio::User.find_by(id: session[:true_user_id])
    else
      current_user
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

    def force_correct_path(correct_path_or_url, ignore_get_params: true)
      # If an old id or a numeric id was used to find the record, then
      # the request path will not match the post_path, and we should do
      # a 301 redirect that uses the current friendly id.
      if ignore_get_params && request.path != correct_path_or_url && request.url.split("?")[0] != correct_path_or_url.split("?")[0]
        redirect_to(correct_path_or_url, status: :moved_permanently)
        true
      elsif !ignore_get_params && request.fullpath != correct_path_or_url && request.url != correct_path_or_url
        redirect_to(correct_path_or_url, status: :moved_permanently)
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
      if session_id = session.id.try(:public_id)
        cookies.signed[:s_for_log] = session_id unless cookies.signed[:s_for_log] == session_id
      else
        cookies.signed[:s_for_log] = nil if cookies.signed[:s_for_log]
      end

      catch(:warden) do
        if user_id = try(:current_user).try(:id)
          cookies.signed[:u_for_log] = user_id unless cookies.signed[:u_for_log] == user_id
        else
          cookies.signed[:u_for_log] = nil if cookies.signed[:u_for_log]
        end
      end
    end

    def current_site_based_layout
      current_site ? current_site.layout_name : "folio/application"
    end

    def authenticate_inviter!
      # allow anonymous invites
    end

    def current_ability
      @current_ability ||= Folio::Ability.new(current_user, current_site)
    end
end
