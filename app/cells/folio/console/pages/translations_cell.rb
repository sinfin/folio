# frozen_string_literal: true

class Folio::Console::Pages::TranslationsCell < Folio::ConsoleCell
  include Folio::Console::FlagHelper
  include ActionView::Helpers::UrlHelper

  def show
    render if multi_language_site
  end

  def multi_language_site
    (locales - [model.locale]).length > 0
  end

  def locales
    Folio::Site.instance.locales
  end

  def ul_class
    return 'nav nav-pills' if options[:as_pills]
    'folio-console-pages-translations-inline'
  end

  def edit_link(page)
    path = controller.edit_console_page_path(page.id)
    link_to(label(page.locale),
            path,
            class: active_class(path))
  end

  def new_link(locale, original)
    path = controller.new_console_page_path('page[locale]': locale,
                                            'page[original_id]': original.id)
    link_to(label(locale),
            path,
            class: "folio-console-not-translated #{active_class(path)}",
            rel: :nofollow,
            data: {
              confirm: translate_message(locale),
            })
  end

  def active_class(path)
    if current_page?(path)
      'nav-link active'
    else
      'nav-link'
    end
  end

  def label(locale)
    if options[:as_pills]
      locale_to_label(locale, short: true)
    else
      country_flag(locale)
    end
  end

  def translate_message(locale)
    t(".confirm_#{locale}", default: t('.confirm', language: locale))
  end
end
