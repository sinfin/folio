# frozen_string_literal: true

class Folio::Console::Layout::SidebarCell < Folio::ConsoleCell
  def site_name
    Folio::Site.instance.title
  end

  def links
    class_names = prepended_link_class_names +
                  %w[Folio::Page] +
                  runner_up_link_class_names +
                  folio_link_class_names +
                  appended_link_class_names

    class_names.map do |class_name|
      klass = class_name.constantize
      label = klass.model_name.human(count: 2)
      path = controller.url_for([:console, klass])
      link(label, path)
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
    %w[
      Folio::Menu
      Folio::Image
      Folio::Document
      Folio::NewsletterSubscription
      Folio::Lead
      Visit
      Folio::Account
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
end
