# frozen_string_literal: true

class Folio::MailerHook < Premailer::Rails::Hook
  MSO_PADDING_START = '<!--[if mso]><i style="mso-font-width:100%;mso-text-raise:100%" hidden>&emsp;</i><span style="mso-text-raise:50%;"><![endif]-->'.html_safe
  MSO_PADDING_END = '<!--[if mso]></span><i style="mso-font-width:100%;" hidden>&emsp;&#8203;</i><![endif]-->'.html_safe

  REDACTOR_BUTTON_REGEX = /(<p[^>]*folio-redactor-button[^>]*><a[^>]*btn-redactor[^>]+>)([^<]+)(<\/a>)/

  def perform
    if html_part && html_part.body && html_part.decoded.match?(REDACTOR_BUTTON_REGEX)
      replace_html_part(generate_html_part_replacement)
    end
  end

  private
    def pad_redactor_buttons_in_html_string(string)
      string.gsub(REDACTOR_BUTTON_REGEX, "\\1#{MSO_PADDING_START}\\2#{MSO_PADDING_END}\\3")
    end

    def generate_html_part
      generate_text_part if generate_text_part?

      html = pad_redactor_buttons_in_html_string(html_part.decoded).html_safe

      Mail::Part.new do
        content_type "text/html; charset=#{html.encoding}"
        body html
      end
    end
end
