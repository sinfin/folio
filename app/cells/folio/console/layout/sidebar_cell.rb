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
    elsif link_source.is_a?(Hash) && (link_source[:klass] || link_source[:label]) && (link_source[:path] || link_source[:url_name])
      if link_source[:klass]
        return unless can_now?(:index, link_source[:klass].constantize)
      end

      label = if link_source[:label]
        link_source[:label].is_a?(Symbol) ? t(".#{link_source[:label]}") : link_source[:label]
      elsif link_source[:klass]
        label_from(link_source[:klass].constantize)
      else
        ""
      end

      if link_source[:url_name]
        begin
          path = controller.send(link_source[:url_name], only_path: false, host: link_source[:host])
        rescue NoMethodError
          path = controller.main_app.send(link_source[:url_name], only_path: false, host: link_source[:host])
        end
      else
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
    shared_links = []
    sites = (current_site == Folio.main_site || current_user.superadmin?) ? Folio::Site.ordered : [current_site]
    if ::Rails.application.config.folio_shared_files_between_sites
      shared_links = [{
        locale: Folio.main_site.console_locale,
        title: nil,
        collapsed: nil,
        expanded: nil,
        links: file_links(Folio.main_site).compact
      }]
      sites = Folio::Site.ordered
    end


    sites_links = sites.filter_map { |site| site_main_links(site) }

    shared_links + sites_links
  end

  def secondary_class_names
    links = []
    links << link_for_site_class(Folio.main_site, Folio::User) if show_users? && current_user.superadmin?

    [
      {
        links: links.compact
      }
    ]
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

    if instance && controller.can_now?(:index, Folio::Page)
      {
        label: t(".homepage"),
        path: controller.url_for([:edit, :console, instance, only_path: false, host: site.env_aware_domain]),
      }
    end
  end

  def show_users?
    !::Rails.application.config.folio_console_sidebar_force_hide_users
  end

  def show_leads?
    ::Rails.application.config.folio_leads_from_component_class_name
  end

  def show_newsletter_subscriptions?
    ::Rails.application.config.folio_newsletter_subscriptions
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

  private
    def site_main_links(site)
      return nil unless controller.can_now?(:read, site)

      build_site_links_collapsible_block(site)
    end

    def file_links(site)
      [ link_for_site_class(site, Folio::File::Image),
        link_for_site_class(site, Folio::File::Video),
        link_for_site_class(site, Folio::File::Audio),
        link_for_site_class(site, Folio::File::Document)]
    end

    def build_site_links_collapsible_block(site)
      I18n.with_locale(site.console_locale) do
        links = ::Rails.application.config.folio_shared_files_between_sites ? [] : file_links(site)
        links << link_for_site_class(site, Folio::ContentTemplate) if ::Rails.application.config.folio_content_templates_editable

        site_links = site_specific_links(site)

        links += site_links[:console_sidebar_prepended_links]
        links << link_for_site_class(site, Folio::Page)
        links << homepage_for_site(site)
        links += site_links[:console_sidebar_before_menu_links]
        links << link_for_site_class(site, Folio::Menu)
        links << link_for_site_class(site, Folio::Lead) if show_leads?
        links << link_for_site_class(site, Folio::NewsletterSubscription) if show_newsletter_subscriptions?
        links << link_for_site_class(site, Folio::EmailTemplate)
        links += site_links[:console_sidebar_before_site_links]
        if can_now?(:update, site)
          links << {
                      klass: "Folio::Site",
                      icon: :cog,
                      path: controller.folio.edit_console_site_url(only_path: false, host: site.env_aware_domain),
                      label: t(".settings"),
                    }
        end
        links << link_for_site_class(site, Folio::User) if show_users? && !current_user.superadmin?

        {
          locale: site.console_locale,
          title: site.pretty_domain,
          collapsed: current_site != site,
          expanded: current_site == site,
          links: links.compact
        }
      end
    end

    def site_specific_links(site)
      site_links = {
        console_sidebar_prepended_links: [],
        console_sidebar_before_menu_links: [],
        console_sidebar_before_site_links: [],
      }

      I18n.with_locale(site.console_locale) do
        site_links.keys.each do |links_group_key|
          next if (group_links_defs = site.class.try(links_group_key)).blank?

          group_links_defs.each do |link_or_hash|
            site_links[links_group_key] << link_from_definitions(site, link_or_hash)
          end
        end
      end
      site_links
    end


    def link_from_definitions(site, link_or_hash)
      if link_or_hash.is_a?(Hash)
        if !link_or_hash[:required_ability] || can_now?(link_or_hash[:required_ability], link_or_hash[:klass].constantize, site:)
          link_or_hash[:host] = site.env_aware_domain if link_or_hash[:url_name]
          link_or_hash
        end
      else
        link_for_site_class(site, link_or_hash.constantize)
      end
    end

    def link_for_site_class(site, klass, params: {}, label: nil)
      return nil unless can_now?(:index, klass, site:)
      {
        klass: klass.to_s,
        label:,
        path: url_for([:console, klass, only_path: false, host: site.env_aware_domain, params:])
      }
    end

    def can_now?(action, object, site: current_site)
      (current_user || Folio::User.new).can_now_by_ability?(site_ability(site), action, object)
    end

    def site_ability(site)
      @site_abilities ||= {}
      @site_abilities[site] ||= Folio::Ability.new(current_user, site)
    end
end
