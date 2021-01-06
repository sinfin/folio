# frozen_string_literal: true

module Folio::HasCurrentSite
  extend ActiveSupport::Concern

  included do
    helper_method :current_site
  end

  def current_site
    @current_site ||= Folio::Site.instance
  end
end
