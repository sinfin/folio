# frozen_string_literal: true

class Folio::Console::Layout::SidebarCell < Folio::ConsoleCell
  def link_groups
    ::Rails.application
           .config
           .folio_console_sidebar_link_class_names || default_link_groups
  end

  def default_link_groups
    prepended_link_class_names +
    main_class_names +
    runner_up_link_class_names +
    secondary_class_names +
    appended_link_class_names
  end

  def filtered_link_groups_with_links
    link_groups.filter_map do |group|
      I18n.with_locale(group[:locale] || I18n.locale) do
        if group[:links].present?
          links = group[:links].filter_map { |l| link_from(l) }

          if links.present?
            group.merge(links:)
          end
        end
      end
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
        return if controller.cannot?(:index, link_source[:klass].constantize)
      end

      label = if link_source[:label]
        link_source[:label].is_a?(Symbol) ? t(".#{link_source[:label]}") : link_source[:label]
      elsif link_source[:klass]
        label_from(link_source[:klass].constantize)
      else
        ""
      end

      if link_source[:path].is_a?(String)
        path = link_source[:path]
      else
        path_params = link_source[:params].presence || {}

        begin
          path = controller.send(link_source[:path], path_params)
        rescue NoMethodError
          path = controller.main_app.send(link_source[:path], path_params)
        end
      end

      paths = (link_source[:paths] || []).map do |p|
        controller.send(p)
      rescue NoMethodError
        controller.main_app.send(p)
      end

      if path.include?("?")
        paths << path.split("?", 2)[0]
      end

      if link_source[:icon]
        link(nil, path, active_start_with: link_source[:active_start_with] != false) do
          concat(folio_icon(link_source[:icon], class: "f-c-layout-sidebar__icon", height: 16))
          concat(content_tag(:span, label, class: "f-c-layout-sidebar__span"))
        end
      else
        link(label, path, paths:,
                          active_start_with: link_source[:active_start_with] != false)
      end
    else
      klass = link_source.constantize

      return if controller.cannot?(:index, klass)

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
      link_to(content_tag(:span, label, class: "f-c-layout-sidebar__span"), path, class: class_names)
    end
  end

  def main_class_names
    if ::Rails.application.config.folio_site_is_a_singleton
      [{
        links: [
          "Folio::Page",
          :homepage,
          "Folio::Menu",
          "Folio::File::Image",
          { klass: "Folio::File::Video", path: url_for([:console, Folio::File::Video]), label: t(".video") },
          { klass: "Folio::File::Audio", path: url_for([:console, Folio::File::Audio]), label: t(".audio") },
          "Folio::File::Document",
          "Folio::ContentTemplate",
        ]
      }]
    else
      [
        {
          links: [
            "Folio::File::Image",
            "Folio::File::Document",
            "Folio::ContentTemplate",
          ]
        }
      ] + Folio::Site.ordered.filter_map do |site|
        if controller.can?(:read, site)
          I18n.with_locale(site.locale) do
            link_for_class = -> (klass) do
              {
                klass: klass.to_s,
                path: url_for([:console, klass, only_path: false, host: site.env_aware_domain])
              }
            end

            site_links = {
              console_sidebar_prepended_links: [],
              console_sidebar_before_menu_links: [],
            }

            %i[
              console_sidebar_before_menu_links
              console_sidebar_prepended_links
            ].each do |key|
              values = site.class.try(key)
              if values.present?
                values.each do |link_or_hash|
                  if link_or_hash.is_a?(Hash)
                    if !link_or_hash[:required_ability] || controller.can?(link_or_hash[:required_ability], link_or_hash[:klass].constantize)
                      site_links[key] << link_or_hash
                    end
                  else
                    site_links[key] << link_for_class.call(link_or_hash.constantize)
                  end
                end
              end
            end

            {
              locale: site.locale,
              title: site.pretty_domain,
              collapsed: current_site != site,
              expanded: current_site == site,
              links: site_links[:console_sidebar_prepended_links].compact + [
                link_for_class.call(Folio::Page),
                homepage_for_site(site)
              ].compact + site_links[:console_sidebar_before_menu_links].compact + [
                link_for_class.call(Folio::Menu),
                link_for_class.call(Folio::Lead),
                link_for_class.call(Folio::NewsletterSubscription),
                link_for_class.call(Folio::EmailTemplate),
                controller.can?(:manage, site) ? (
                  {
                    klass: "Folio::Site",
                    icon: :cog,
                    path: controller.folio.edit_console_site_url(only_path: false, host: site.env_aware_domain),
                    label: t(".settings"),
                  }
                ) : nil,
              ].compact
            }
          end
        end
      end
    end
  end

  def secondary_class_names
    if ::Rails.application.config.folio_site_is_a_singleton
      [
        show_users? ? { links: %w[Folio::User] } : nil,
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
              icon: :cog,
              path: :edit_console_site_path,
              label: t(".settings")
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
    @homepage_instance ||= "#{::Rails.application.class.name.deconstantize}::Page::Homepage".safe_constantize.try(:instance, fail_on_missing: false, site: current_site)
  end

  def homepage_for_site(site)
    instance = "#{site.class.name.deconstantize}::Page::Homepage".safe_constantize.try(:instance, fail_on_missing: false, site: current_site)

    if instance && controller.can?(:index, Folio::Page)
      {
        label: t(".homepage"),
        path: controller.url_for([:edit, :console, instance, only_path: false, host: site.env_aware_domain]),
      }
    end
  end

  def show_users?
    ::Rails.application.config.folio_users && !::Rails.application.config.folio_console_sidebar_force_hide_users
  end

  def group_class_name(group)
    ary = []

    ary << "f-c-layout-sidebar__group--collapsed" if group[:collapsed]
    ary << "f-c-layout-sidebar__group--expanded" if group[:expanded]

    ary
  end

  def show_search?
    true
  end
end
