# frozen_string_literal: true

module Folio::SetCurrentRequestDetails
  extend ActiveSupport::Concern

  included do
    prepend_before_action :set_up_current_from_request
  end

  private
    def set_up_current_from_request
      if Folio::Current.request_id.nil? || (request && request.uuid != Folio::Current.request_id)
        site = Folio.current_site(request:, controller: self)

        # warden takes params from request, so we need to set source_site_id here,
        # before searching for current user
        request.params["user"]["source_site_id"] = site.id.to_s if request.params["user"].present?
        user = current_user

        Folio::Current.setup!(request:, site:, user:, session:)
      end
    end
end
