# frozen_string_literal: true

class Folio::Console::Layout::SidebarCell < Folio::ConsoleCell
  def site_name
    current_site.title
  end

  def link_groups
    if ::Rails.application.config.folio_console_sidebar_link_class_names
      ::Rails.application
             .config
             .folio_console_sidebar_link_class_names
    else
      prepended_link_class_names +
      main_class_names +
      runner_up_link_class_names +
      secondary_class_names +
      appended_link_class_names
    end
  end

  def link_from(link_source)
    return if skip_link_class_names.include?(link_source)

    if link_source == :homepage
      if homepage_instance
        path = controller.url_for([:edit, :console, homepage_instance])
        link(t(".homepage"), path)
      end
    elsif link_source.is_a?(Hash) && (link_source[:klass] || link_source[:label]) && link_source[:path]
      if link_source[:klass]
        return if controller.cannot?(:read, link_source[:klass].constantize)
      end

      label = if link_source[:label]
        t(".#{link_source[:label]}")
      elsif link_source[:klass]
        label_from(link_source[:klass].constantize)
      else
        ""
      end

      if link_source[:path].is_a?(String)
        path = link_source[:path]
      else
        begin
          path = controller.send(link_source[:path])
        rescue NoMethodError
          path = controller.main_app.send(link_source[:path])
        end
      end

      paths = (link_source[:paths] || []).map do |p|
        controller.send(p)
      rescue NoMethodError
        controller.main_app.send(p)
      end

      if link_source[:icon]
        link(nil, path, active_start_with: link_source[:active_start_with]) do
          concat(content_tag(:i, "", class: "#{link_source[:icon]} f-c-layout-sidebar__icon"))
          concat(label)
        end
      else
        link(label, path, paths:,
                          active_start_with: link_source[:active_start_with])
      end
    else
      klass = link_source.constantize

      return if controller.cannot?(:read, klass)

      label = label_from(klass)
      path = controller.url_for([:console, klass])
      link(label, path)
    end
  end

  def link(label, path, paths: [], active_start_with: true, &block)
    active = ([path] + paths).any? do |p|
      start = p.split("?").first
      if active_start_with
        request.path.start_with?(start) || request.url.start_with?(start)
      else
        request.path == p || request.url == p
      end
    end

    if active && path == url_for([:console, Folio::Page]) && homepage_instance
      url = url_for([:edit, :console, homepage_instance])
      if (request.path == url) || (request.url == url)
        active = false
      end
    end

    class_names = ["f-c-layout-sidebar__a"]
    class_names << "f-c-layout-sidebar__a--active" if active

    if block_given?
      link_to(path, class: class_names, &block)
    else
      link_to(label, path, class: class_names)
    end
  end

  def main_class_names
    if ::Rails.application.config.folio_site_is_a_singleton
      [{
        links: [
          "Folio::Page",
          :homepage,
          "Folio::Menu",
          "Folio::Image",
          "Folio::Document",
          "Folio::ContentTemplate",
        ]
      }]
    else
      [
        {
          links: [
            "Folio::Image",
            "Folio::Document",
            "Folio::ContentTemplate",
          ]
        }
      ] + Folio::Site.ordered.map do |site|
        link_for_class = -> (klass) do
          {
            klass: klass.to_s,
            path: url_for([:console, klass, only_path: false, host: site.env_aware_domain])
          }
        end

        {
          title: site.title,
          links: [
            link_for_class.call(Folio::Page),
            homepage_for_site(site),
            link_for_class.call(Folio::Menu),
            link_for_class.call(Folio::Lead),
            link_for_class.call(Folio::NewsletterSubscription),
            link_for_class.call(Folio::EmailTemplate),
            {
              klass: "Folio::Site",
              icon: "fa fa-cogs",
              path: controller.folio.edit_console_site_url(only_path: false, host: site.env_aware_domain),
              label: "settings"
            },
          ].compact
        }
      end
    end
  end

  def secondary_class_names
    if ::Rails.application.config.folio_site_is_a_singleton
      [
        ::Rails.application.config.folio_users ? { links: %w[Folio::User] } : nil,
        {
          links: %w[
            Folio::Lead
            Folio::NewsletterSubscription
          ],
        },
        {
          links: [
            "Folio::Account",
            "Folio::EmailTemplate",
            {
              klass: "Folio::Site",
              icon: "fa fa-cogs",
              path: :edit_console_site_path,
              label: "settings"
            },
          ]
        }
      ].compact
    else
      [
        {
          links: [
            ::Rails.application.config.folio_users ? "Folio::User" : nil,
            "Folio::Account",
          ].compact
        }
      ]
    end
  end

  def prepended_link_class_names
    ::Rails.application.config.folio_console_sidebar_prepended_link_class_names
  end

  def appended_link_class_names
    ::Rails.application.config.folio_console_sidebar_appended_link_class_names
  end

  def runner_up_link_class_names
    ::Rails.application.config.folio_console_sidebar_runner_up_link_class_names
  end

  def skip_link_class_names
    ::Rails.application.config.folio_console_sidebar_skip_link_class_names || []
  end

  def label_from(klass)
    label = klass.model_name.human(count: 2)

    if klass.respond_to?(:console_sidebar_count)
      count = klass.console_sidebar_count
      if count && count != 0
        return "#{label} <strong class=\"font-weight-bold\">(#{count})</strong>"
      end
    end

    label
  end

  def homepage_instance
    @homepage_instance ||= "#{::Rails.application.class.name.deconstantize}::Page::Homepage".safe_constantize.try(:instance, fail_on_missing: false)
  end

  def homepage_for_site(site)
    instance = "#{site.class.name.deconstantize}::Page::Homepage".safe_constantize.try(:instance, fail_on_missing: false)

    if instance
      {
        label: t(".homepage"),
        path: controller.url_for([:edit, :console, instance, only_path: false, host: site.env_aware_domain]),
      }
    end
  end
end
