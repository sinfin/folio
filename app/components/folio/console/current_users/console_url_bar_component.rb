# frozen_string_literal: true

class Folio::Console::CurrentUsers::ConsoleUrlBarComponent < Folio::Console::ApplicationComponent
  attr_reader :show

  def initialize(show:)
    @show = show
  end

  def render
    @show && can_now?(:access_console)
  end

  private
    def other_user_at_url
      return false unless can_now?(:access_console)
      return @other_user_at_url unless @other_user_at_url.nil?
      @other_user_at_url = Folio::User.currently_editing_url(request.url).where.not(id: Folio::Current.user.id).first || false
    end

    def hidden?
      other_user_at_url == false
    end

    def name
      if other_user_at_url
        other_user_at_url.to_label
      end
    end

    def data
      stimulus_controller("f-c-current-users-console-url-bar",
                          values: {
                            api_url: controller.console_url_ping_console_api_current_user_url(format: :json)
                          })
    end
end
