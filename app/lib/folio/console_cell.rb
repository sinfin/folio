# frozen_string_literal: true

class Folio::ConsoleCell < Folio::ApplicationCell
  include Folio::Cell::HtmlSafeFieldsFor
  include Folio::Console::CellsHelper
  include Folio::Console::ReportsHelper

  delegate :safe_url_for,
           :through_aware_console_url_for,
           to: :controller

  def url_for(*args)
    controller.url_for(*args)
  end

  def admin_image(placement, opts = {})
    cell("folio/image",
         placement,
         opts.reverse_merge(size: Folio::Console::FileSerializer::ADMIN_THUMBNAIL_SIZE,
                            contain: true))
  end

  def sanitize_string(str)
    if str.present? && str.is_a?(String)
      ActionController::Base.helpers.sanitize(str, tags: [], attributes: [])
    else
      str
    end
  end

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

    begin
      I18n.with_locale(args[:locale] || I18n.locale) { url_for([record, args]) }
    rescue NoMethodError
      nil
    end
  end
end
