# frozen_string_literal: true

class Folio::Console::EmailMessagesController < Folio::Console::BaseController
  folio_console_controller_for "Emailbutler::Message"

  private
    def index_filters
      {}
    end

    def folio_console_record_includes
      []
    end
end
