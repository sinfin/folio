# frozen_string_literal: true

class Dummy::Mailer::BaseComponent < ApplicationComponent
  ALLOWED_SEPARATORS = [" ", ".", ":"]
  HTML_ENTITY = "&#173;"

  # Function for prevent automatic conversion to link
  # Some mobile clients make this automatic conversion, eg. for amounts
  # Without this hack, eg. the amount 100 000 would be converted to a (broken) link
  def insert_html_entity(string)
    sanitized_string = sanitize(string)

    ALLOWED_SEPARATORS.each do |separator|
      sanitized_string = sanitized_string.gsub(separator, "#{HTML_ENTITY}#{separator}")
    end

    sanitized_string.html_safe
  end

  def menu_url_for(menu_item)
    string = super

    if string.start_with?("/")
      "#{@site.env_aware_root_url}#{string[1..]}"
    else
      string
    end
  end
end
