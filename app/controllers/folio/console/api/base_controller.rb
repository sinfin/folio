# frozen_string_literal: true

class Folio::Console::Api::BaseController < Folio::Console::BaseController
  include Folio::ApiControllerBase

  skip_before_action :authenticate_account!
  before_action :api_authenticate_account!

  private
    def api_authenticate_account!
      fail CanCan::AccessDenied if current_account.blank?
    end
end
