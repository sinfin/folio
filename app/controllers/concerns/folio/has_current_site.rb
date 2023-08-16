# frozen_string_literal: true

module Folio::HasCurrentSite
  extend ActiveSupport::Concern

  included do
    helper_method :current_site
  end

  def current_site
    @current_site ||= if ::Rails.application.config.folio_site_cache_current_site && respond_to?(:cache_key_base)
      Rails.cache.fetch(["current_site", request.host] + cache_key_base) do
        Folio.current_site(request:, controller: self)
      end
    else
      Folio.current_site(request:, controller: self)
    end
  end
end
