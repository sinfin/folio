# frozen_string_literal: true

class Folio::Console::CurrentUsers::PresencePingComponent < Folio::Console::ApplicationComponent
  def initialize(record: nil)
    @record = record
  end

  def render?
    can_now?(:access_console)
  end

  private
    def data
      stimulus_controller("f-c-current-users-presence-ping",
                          values: {
                            api_url: ping_console_url,
                            presence_url: helpers.folio_console_presence_url,
                            record_id: @record&.id,
                            record_type: @record&.class&.name,
                          })
    end

    def ping_console_url
      if ["1", "true"].include?(ENV.fetch("DONT_PING_CONSOLE", "").to_s.downcase)
        "dont_ping"
      else
        controller.console_url_ping_console_api_current_user_url(format: :json)
      end
    end
end
