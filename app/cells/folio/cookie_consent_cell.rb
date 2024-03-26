# frozen_string_literal: true

class Folio::CookieConsentCell < Folio::ApplicationCell
  DISABLED_SCRIPT_TYPE = "text/plain"
  ANALYTICS_CATEGORY = "analytics"

  def self.known_cookies
    {
      cc_cookie: {
        expiration: [1, :years],
        description: {
          cs: "Udržuje nastavení cookies z toho okna.",
          en: "Maintains cookie configuration made from this window.",
        }
      },
      session_id: {
        name: "_#{::Rails.application.class.name.deconstantize.underscore}_session",
        expiration: :end_of_session,
        description: {
          cs: "Udržuje výsledky uživatelské aktivity na webu, jako je např. příhlášení či obsah košíku.",
          en: "Maintains the results of user activity on the site, such as login or cart content.",
        }
      },
      remember_user_token: {
        expiration: [1, :years],
        description: {
          cs: "Udržuje příhlášení uživatele.",
          en: "Keeps the user signed in.",
        }
      },
      s_for_log: {
        expiration: :end_of_session,
        description: {
          cs: "Umožňuje podporu uživatelů identifikací požadavků v logu aplikace.",
          en: "Enables user support by identifying requests in the application log.",
        }
      },
      u_for_log: {
        expiration: :end_of_session,
        description: {
          cs: "Umožňuje podporu uživatelů identifikací požadavků v logu aplikace.",
          en: "Enables user support by identifying requests in the application log.",
        }
      },
      _ga: {
        expiration: [2, :years],
        description: {
          cs: "Používá se k rozlišení uživatelů.",
          en: "Used to distinguish users.",
        }
      },
      _gat: {
        name: "_gat_.*",
        is_regex: true,
        expiration: [1, :minutes],
        description: {
          cs: "Tento soubor cookie neukládá žádné informace o uživateli; používá se pouze k omezení počtu požadavků, které je třeba provést na doubleclick.net.",
          en: "This cookie does not store any user information; it's just used to limit the number of requests that have to be made to doubleclick.net.",
        }
      },
      _gid: {
        expiration: [24, :hours],
        description: {
          cs: "Používá se k rozlišení uživatelů.",
          en: "Used to distinguish users.",
        }
      },
      _ga_container_id: {
        name: "_ga_.*",
        is_regex: true,
        expiration: [2, :years],
        description: {
          cs: "Používá se k zachování stavu relace.",
          en: "Used to persist session state.",
        }
      },
      _gac_gb_container_id: {
        name: "_gac_.*",
        is_regex: true,
        expiration: [90, :days],
        description: {
          cs: "Obsahuje informace související s kampaní.",
          en: "Contains campaign related information.",
        }
      },
      _gcl_au: {
        expiration: [1, :years],
        description: {
          cs: "Ukládá informace o prokliku reklam.",
          en: "Stores information about ad clicks.",
        }
      },
      _fbp: {
        expiration: [3, :months],
        description: {
          cs: "Používá se k rozlišení uživatelů.",
          en: "Used to distinguish users.",
        }
      },
      NID: {
        expiration: [6, :months],
        domain: ".google.com",
        description: {
          cs: "Udržuje uživatelská nastavení.",
          en: "Stores user preferences.",
        }
      },
    }
  end

  def show
    render if config && config[:enabled]
  end

  def config
    ::Rails.application.config.folio_cookie_consent_configuration
  end

  def locales
    I18n.available_locales
  end

  def configuration_hash
    {
      current_lang: I18n.locale,
      autoclear_cookies: true,
      page_scripts: true,
      languages: { I18n.locale => languages_hash },
      gui_options: {
        consent_modal: {
          layout: "cloud",
          position: "bottom center",
          transition: "slide",
        }
      }
    }
  end

  def cookies_page_url
    if p = try(:current_page_singleton, "#{::Rails.application.class.name.deconstantize}::Page::Cookies".safe_constantize)
      return url_for(p)
    end

    klass = "#{::Rails.application.class.name.deconstantize}::Page::Cookies".safe_constantize

    if klass && instance = klass.instance(fail_on_missing: false, site: try(:current_site))
      return url_for(instance)
    end

    if p = try(:current_page_singleton, "::Folio::Page::Cookies")
      return url_for(p)
    end

    klass = "::Folio::Page::Cookies".safe_constantize

    if klass && instance = klass.instance(fail_on_missing: false)
      url_for(instance)
    end
  rescue StandardError
  end

  def languages_hash
    if cookies_page_url.present?
      cookies_link = link_to(t(".cookies_link"), cookies_page_url, class: "cc-link")
    else
      cookies_link = ""
    end

    blocks = [
      {
        title: t(".consent_modal.settings_modal.blocks.title"),
        description: t(".consent_modal.settings_modal.blocks.description", cookies_link:)
      }
    ]

    %i[necessary analytics marketing].each do |key|
      next if config[:cookies][key].blank?

      blocks << {
        title: t(".consent_modal.settings_modal.blocks.#{key}.title"),
        description: t(".consent_modal.settings_modal.blocks.#{key}.description"),
        cookie_table: cookie_table(key),
        toggle: {
          value: key.to_s,
          enabled: key == :necessary,
          readonly: key == :necessary,
        }
      }
    end

    {
      consent_modal: {
        title: t(".consent_modal.title"),
        description: t(".consent_modal.description", cookies_link:),
        primary_btn: {
          text: t(".consent_modal.primary_btn.text"),
          role: "accept_all"
        },
        secondary_btn: {
          text: t(".consent_modal.secondary_btn.text"),
          role: "settings"
        }
      },
      settings_modal: {
        title: t(".consent_modal.settings_modal.title"),
        save_settings_btn: t(".consent_modal.settings_modal.save_settings_btn"),
        accept_all_btn: t(".consent_modal.settings_modal.accept_all_btn"),
        reject_all_btn: t(".consent_modal.settings_modal.reject_all_btn"),
        close_btn_label: t(".consent_modal.settings_modal.close_btn_label"),
        cookie_table_headers: [
          { col1: t(".consent_modal.settings_modal.cookie_table_headers.col1") },
          { col2: t(".consent_modal.settings_modal.cookie_table_headers.col2") },
          { col3: t(".consent_modal.settings_modal.cookie_table_headers.col3") },
          { col4: t(".consent_modal.settings_modal.cookie_table_headers.col4") }
        ],
        blocks:,
      }
    }
  end

  def cookie_table(key)
    ary = []

    config[:cookies][key].each do |symbol_or_hash|
      if symbol_or_hash.is_a?(Symbol)
        if self.class.known_cookies[symbol_or_hash]
          ary << cookie_setting_for_known_key(symbol_or_hash)
        else
          log_error("Missing definition for cookie symbol - #{symbol_or_hash}")
        end
      elsif symbol_or_hash.is_a?(Hash)
        ary << cookie_setting_for_hash(symbol_or_hash)
      else
        log_error("Unknown definition of a cookie", extra: symbol_or_hash)
      end
    end

    ary
  end

  def cookie_setting_for_known_key(key)
    h = self.class.known_cookies[key]

    {
      col1: h[:name] || key.to_s,
      col2: h[:domain].presence || model,
      col3: h[:expiration] == :end_of_session ? t(".expiration.end_of_session") : t(".expiration.#{h[:expiration][1]}", count: h[:expiration][0]),
      col4: h[:description][I18n.locale] || h[:description][:en],
      is_regex: h[:is_regex] == true,
    }
  end

  def cookie_setting_for_hash(h)
    {
      col1: h[:name],
      col2: h[:domain].presence || model,
      col3: h[:expiration] == :end_of_session ? t(".expiration.end_of_session") : t(".expiration.#{h[:expiration][1]}", count: h[:expiration][0]),
      col4: h[:description][I18n.locale] || h[:description][:en],
      is_regex: h[:is_regex] == true,
    }
  end

  def log_error(msg, extra: nil)
    Raven.capture_message(msg, extra:)
  rescue StandardError
  end
end
