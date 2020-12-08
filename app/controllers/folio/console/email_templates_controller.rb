# frozen_string_literal: true

class Folio::Console::EmailTemplatesController < Folio::Console::BaseController
  folio_console_controller_for "Folio::EmailTemplate"

  private
    def email_template_params
      params.require(:email_template)
            .permit(:title,
                    :subject,
                    :body)
    end
end
