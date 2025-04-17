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
          # don't use `.site` here as that would try to fetch one without host and cache it
          request.params["user"]["auth_site_id"] = Folio::Current.get_site(host: request.host).id.to_s
        end

        Folio::Current.setup!(request:,
                              user: current_user,
                              session:,
                              cache_key_base: Rails.application.config.action_controller.perform_caching ? try(:cache_key_base) : nil)
      end
    end
end
