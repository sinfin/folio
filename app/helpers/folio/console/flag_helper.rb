# frozen_string_literal: true

module Folio
  module Console::FlagHelper
    CDN = 'https://cdnjs.cloudflare.com/ajax/libs/flag-icon-css/2.9.0/flags'

    def country_flag(locale)
      code = Folio::LANGUAGES[locale.to_sym]
      return locale unless code
      image_tag("#{CDN}/4x3/#{code.downcase}.svg",
                alt: code,
                class: 'folio-console-flag')
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
      ].join(' ').html_safe
    end
  end
end
