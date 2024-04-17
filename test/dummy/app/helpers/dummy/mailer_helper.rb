# frozen_string_literal: true

module Dummy::MailerHelper
  ALLOWED_SEPARATORS = [" ", ".", ":"]
  HTML_ENTITY = "&#173;"

  # function for prevent automatic conversion to link
  def insert_html_entity(string)
    sanitized_string = sanitize(string)

    ALLOWED_SEPARATORS.each do |separator|
      sanitized_string = sanitized_string.gsub(separator, "#{HTML_ENTITY}#{separator}")
    end

    sanitized_string.html_safe
  end
end
