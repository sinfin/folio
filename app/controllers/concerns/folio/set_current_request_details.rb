# frozen_string_literal: true

module Folio::SetCurrentRequestDetails
  extend ActiveSupport::Concern

  included do
    prepend_before_action :set_up_current_from_request
  end

  private
    def set_up_current_from_request
      if Folio::Current.request_id.nil? || (request && request.uuid != Folio::Current.request_id)
        # warden takes params from request, so we need to set source_site_id here,
        # before searching for current user
        if request.params["user"].present? && request.params["user"]["auth_site_id"].blank?
          request.params["user"]["auth_site_id"] = Folio::Current.site.id.to_s
        end

        Folio::Current.setup!(request:, user: current_user, session:)
      end
    end
end
