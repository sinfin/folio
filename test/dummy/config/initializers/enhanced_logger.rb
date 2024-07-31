# frozen_string_literal: true

# includes HOSTNAME in Started.... message url
class URLLogger < Rails::Rack::Logger
  def started_request_message(request)
    'Started %s "%s%s%s" for %s at %s' % [
      request.request_method,
      request.protocol,
      request.host_with_port,
      request.filtered_path,
      request.ip,
      Time.now.to_s ]
  end
end

Rails.application.config.middleware.insert_before(Rails::Rack::Logger, URLLogger)
Rails.application.config.middleware.delete(Rails::Rack::Logger)
