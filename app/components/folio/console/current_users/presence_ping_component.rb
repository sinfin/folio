# frozen_string_literal: true

class Folio::Console::CurrentUsers::PresencePingComponent < Folio::Console::ApplicationComponent
  def initialize(record: nil)
    @record = record
  end

  def render?
    can_now?(:access_console)
  end

  PLACEMENT_VERIFIER_PURPOSE = "folio_console_presence_placement"

  private
    def data
      stimulus_controller("f-c-current-users-presence-ping",
                          values: {
                            api_url: ping_console_url,
                            presence_url:,
                            placement_token:,
                          }.compact)
    end

    def presence_url
      helpers.folio_console_presence_url
    end

    # The page knows both the record and its (possibly nested/host-app) presence
    # URL, so it signs them together. The API trusts this signed assertion and
    # never re-derives the URL from the record — which it could not do for nested
    # console routes that need a parent id the API request does not carry.
    def placement_token
      return nil if @record.blank?

      Rails.application.message_verifier(PLACEMENT_VERIFIER_PURPOSE).generate({
        "type" => @record.class.name,
        "id" => @record.id,
        "url" => presence_url,
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
