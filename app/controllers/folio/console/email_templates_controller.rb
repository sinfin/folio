# frozen_string_literal: true

class Folio::Console::EmailTemplatesController < Folio::Console::BaseController
  folio_console_controller_for "Folio::EmailTemplate"

  def index
    # disable pagination
  end

  private
    def email_template_params
      black_list = %w[id
                      mailer
                      action
                      slug
                      required_keywords
                      optional_keywords]

      params.require(:email_template)
            .permit(*(Folio::EmailTemplate.column_names - black_list))
    end
end
