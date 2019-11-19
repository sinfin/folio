# frozen_string_literal: true

class Folio::Console::Layout::SidebarCell < Folio::ConsoleCell
  def site_name
    Folio::Site.instance.title
  end

  def link_groups
    if ::Rails.application.config.folio_console_sidebar_link_class_names
      class_names = ::Rails.application
                           .config
                           .folio_console_sidebar_link_class_names
    else
      class_names = prepended_link_class_names +
                    [%w[
                      Folio::Page
                      Folio::Menu
                      Folio::Image
                      Folio::Document
                    ]] +
                    runner_up_link_class_names +
                    folio_link_class_names +
                    appended_link_class_names
    end

    link_groups_from(class_names)
  end

  def link_groups_from(class_name)
    if class_name.is_a?(Array)
      class_name.map { |cn| link_groups_from(cn) }.compact
    else
      return if skip_link_class_names.include?(class_name)
      klass = class_name.constantize

      if klass == Folio::Site
        link(nil, controller.edit_console_site_path) do
          concat(content_tag(:i,
                             '',
                             class: 'fa fa-cogs f-c-layout-sidebar__icon'))
          concat(t('.settings'))
        end
      else
        label = klass.model_name.human(count: 2)
        path = controller.url_for([:console, klass])
        link(label, path)
      end
    end
  end

  def link(label, path, &block)
    active = request.path.start_with?(path.split('?').first) ||
             request.url.start_with?(path.split('?').first)

    class_names = ['f-c-layout-sidebar__a']
    class_names << 'f-c-layout-sidebar__a--active' if active

    if block_given?
      link_to(path, class: class_names, &block)
    else
      link_to(label, path, class: class_names)
    end
  end

  def folio_link_class_names
    [
      %w[
        Folio::NewsletterSubscription
        Folio::Lead
        Visit
      ],
      %w[
        Folio::Account
        Folio::Site
      ]
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
end
