# frozen_string_literal: true

module Folio::SetCurrentRequestDetails
  extend ActiveSupport::Concern

  included do
    prepend_before_action :set_up_current_from_request
  end

  private
    def set_up_current_from_request
      if defined?(::Current)
        ::Current.request_id = request.uuid
        ::Current.user_agent = request.user_agent
        ::Current.ip_address = request.ip
        ::Current.url = request.url
        ::Current.site = current_site # TODO merge Folio::HasCurrentSite ?
        ::Current.user = current_user
      end
    end
end
