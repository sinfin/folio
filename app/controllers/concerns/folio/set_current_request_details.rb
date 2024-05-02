# frozen_string_literal: true

module Folio::SetCurrentRequestDetails
  extend ActiveSupport::Concern

  included do
    prepend_before_action :set_up_current_from_request
  end

  private
    def set_up_current_from_request
      if Folio::Current.request_id.nil?
        Folio::Current.setup!(request:, site: current_site, user: current_user, session:)
      end
    end
end
