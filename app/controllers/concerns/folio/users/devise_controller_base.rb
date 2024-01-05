# frozen_string_literal: true

module Folio::Users::DeviseControllerBase
  extend ActiveSupport::Concern
  include Folio::Devise::CrossdomainController

  def after_sign_in_path_for(_resource)
    stored_location_for(:user) ||
    main_app.send(Rails.application.config.folio_users_after_sign_in_path)
  end

  def after_sign_out_path_for(_resource)
    main_app.send(Rails.application.config.folio_users_after_sign_out_path)
  end

  def after_sign_up_path_for(_resource)
    stored_location_for(:user) ||
    main_app.send(Rails.application.config.folio_users_after_sign_up_path)
  end

  def after_accept_path_for(_resource)
    stored_location_for(:user) ||
    main_app.send(Rails.application.config.folio_users_after_accept_path)
  end

  def signed_in_root_path(_resource)
    main_app.send(Rails.application.config.folio_users_signed_in_root_path)
  end

  def set_flash_message(key, kind, options = {})
    if key == :notice
      super(:success, kind, options)
    else
      super(key, kind, options)
    end
  end

  def is_flashing_format?
    if @force_flash
      true
    else
      super
    end
  end

  def sign_in(resource_or_scope, *args)
    super
    acquire_orphan_records!
    create_site_user_link
  end

  def email_belongs_to_invited_pending_user?(email)
    user = Folio::User.find_by(email:)
    user && user.invitation_created_at? && user.invitation_accepted_at.nil? && user.sign_in_count == 0
  end

  protected
    # override devise signed in check - redirect to source site if needed
    def require_no_authentication
      result = handle_crossdomain_devise
      super if result && result.action == :noop
    end

    def acquire_orphan_records!
      if resource && session && session.id && session.id.public_id
        resource.acquire_orphan_records!(old_session_id: session.id.public_id)
      end
    end

    def create_site_user_link
      if resource && resource.respond_to?(:site_user_links)
        resource.create_site_links_for([current_site])
      end
    end
end
