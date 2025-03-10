# frozen_string_literal: true

class Folio::Console::ApplicationComponent < Folio::ApplicationComponent
  include Folio::Console::UiHelper

  def preview_url_for(record)
    args = {}

    if record.respond_to?(:published?) && token = record.try(:preview_token)
      args[Folio::Publishable::PREVIEW_PARAM_NAME] = token unless record.published?
    end

    if record.respond_to?(:locale)
      args[:locale] = record.locale
    elsif ::Rails.application.config.folio_console_add_locale_to_preview_links
      args[:locale] = I18n.locale
    end

    if args[:locale] && Folio::Current.site.locale.present? && Folio::Current.site.locales.present? && Folio::Current.site.locales.exclude?(args[:locale].to_s)
      args[:locale] = Folio::Current.site.locale
    end

    args[:only_path] = false if args[:only_path].nil?

    begin
      url_for([record, args])
    rescue NoMethodError
      nil
    end
  end
end
