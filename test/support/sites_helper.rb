# frozen_string_literal: true

module SitesHelper
  private
    def get_any_site
      ::Folio::Site.first || create(:folio_site)
    end
end
