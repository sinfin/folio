# frozen_string_literal: true

module Folio::Console::FlagHelper
  CDN = "https://cdnjs.cloudflare.com/ajax/libs/flag-icon-css/2.9.0/flags"

  def country_flag(locale)
    code = Folio::LANGUAGES[locale.to_sym]
    code ||= locale
    image_tag("#{CDN}/4x3/#{code.downcase}.svg",
              alt: code,
              class: "folio-console-flag")
  end

  def locale_to_label(locale, short: false)
    if short
      text = locale
    else
      text = t("folio.locale.languages.#{locale}")
    end

    [
      text,
      country_flag(locale)
    ].join(" ").html_safe
  end

  def flag_checkboxes
    I18n.available_locales.map do |locale|
      [country_flag(locale), locale]
    end
  end
end
