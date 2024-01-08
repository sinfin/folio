# frozen_string_literal: true

class Folio::Console::Api::BaseController < Folio::Console::BaseController
  include Folio::ApiControllerBase

  skip_before_action :custom_authorize_user!
  before_action :api_authorize_user!

  private
    def serializer_for(model)
      name = model.class.name.gsub("Folio::", "")
      serializer = "Folio::Console::#{name}Serializer".safe_constantize
      serializer ||= "#{name}Serializer".safe_constantize
      fail ArgumentError.new("Unknown serializer") if serializer.nil?
      serializer
    end

    def api_authorize_user!
      fail CanCan::AccessDenied unless can_now?(:access_console, current_site)
    end
end
