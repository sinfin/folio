# frozen_string_literal: true

class Folio::Console::EmailTemplatesController < Folio::Console::BaseController
  folio_console_controller_for "Folio::EmailTemplate"

  def index
    # disable pagination
    @email_templates = @email_templates.ordered
  end

  private
    def additional_email_template_params
      # to be overriden in main_app should it be needed
      []
    end

    def email_template_params
      params.require(:email_template)
            .permit(*traco_aware_param_names(:subject, :body_html, :body_text),
                    :title,
                    :active,
                    *additional_email_template_params)
    end
end
