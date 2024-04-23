# frozen_string_literal: true

module Folio::SetCurrentRequestDetails
  extend ActiveSupport::Concern

  included do
    before_action do
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
end
