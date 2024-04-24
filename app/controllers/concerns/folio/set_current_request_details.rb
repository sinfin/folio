# frozen_string_literal: true

module Folio::SetCurrentRequestDetails
  extend ActiveSupport::Concern

  included do
    prepend_before_action :set_up_current_from_request
  end

  private
    def set_up_current_from_request
      if Folio::Current.request_id.nil?
        Folio::Current.request_id = request.uuid
        Folio::Current.user_agent = request.user_agent
        Folio::Current.ip_address = request.ip
        Folio::Current.url = request.url
        Folio::Current.site = current_site # TODO merge Folio::HasCurrentSite ?
        Folio::Current.user = current_user
      end
    end
end
