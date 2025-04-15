# frozen_string_literal: true

module Folio::Console::PreviewUrlFor
  def preview_url_for_page(record)
    locale = if ::Rails.application.config.folio_pages_locales && record.locale.present?
      if Folio::Current.site.locale.present? &&
         Folio::Current.site.locales.present? &&
         Folio::Current.site.locales.exclude?(record.locale)
        return nil
      else
        record.locale
      end
    else
      nil
    end

    if record.class.try(:public?)
      if record.published?
        controller.main_app.page_url(record.to_preview_param,
                                     locale:,
                                     only_path: false)
      else
        controller.main_app.page_url(record.to_preview_param,
                                     locale:,
                                     only_path: false,
                                     Folio::Publishable::PREVIEW_PARAM_NAME => record.preview_token)
      end
    elsif record.class.try(:public_rails_path)
      controller.main_app.send(record.class.public_rails_path.to_s.gsub(/_path$/, "_url"),
                               locale:,
                               only_path: false)
    else
      nil
    end
  rescue NoMethodError
    nil
  end

  def preview_url_for(record)
    procs = Rails.application.config.folio_console_preview_url_for_procs

    if procs.present?
      target_proc = procs[record.class.to_s] || procs[record.class.base_class.to_s]

      if target_proc
        begin
          return target_proc.call(record, controller)
        rescue StandardError
        end

        return nil
      end
    end

    if record.is_a?(Folio::Page)
      return preview_url_for_page(record)
    end

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
