# frozen_string_literal: true

module Folio::HasCurrentSite
  extend ActiveSupport::Concern

  included do
    helper_method :current_site
  end

  def current_site
    if ::Rails.application.config.cache_classes
      @current_site ||= if ::Rails.application.config.action_controller.perform_caching &&
                           ::Rails.application.config.folio_site_cache_current_site &&
                           respond_to?(:cache_key_base)
        Rails.cache.fetch(["current_site", request.host] + cache_key_base) do
          Folio.current_site(request:, controller: self)
        end
      else
        Folio.current_site(request:, controller: self)
      end
    else
      Folio.current_site(request:, controller: self)
    end
  end

  def current_site_user_link
    @current_site_user_link ||= if current_site && try(:current_user)
      current_user.site_user_links.find_by(site: current_site)
    end
  end
end
