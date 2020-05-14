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
                      Folio::ContentTemplate
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

      if class_name.is_a?(Hash) &&
         class_name.try(:[], :klass) &&
         class_name.try(:[], :path)
        label = label_from(class_name[:klass].constantize)

        begin
          path = controller.send(class_name[:path])
        rescue NoMethodError
          path = controller.main_app.send(class_name[:path])
        end

        paths = (class_name[:paths] || []).map do |p|
          controller.send(p)
        rescue NoMethodError
          controller.main_app.send(p)
        end

        link(label, path, paths: paths)
      else
        klass = class_name.constantize

        if klass == Folio::Site
          link(nil, controller.edit_console_site_path) do
            concat(content_tag(:i,
                               '',
                               class: 'fa fa-cogs f-c-layout-sidebar__icon'))
            concat(t('.settings'))
          end
        else
          label = label_from(klass)
          path = controller.url_for([:console, klass])
          link(label, path)
        end
      end
    end
  end

  def link(label, path, paths: [], &block)
    active = ([path] + paths).any? do |p|
      start = p.split('?').first
      request.path.start_with?(start) || request.url.start_with?(start)
    end

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

  def label_from(klass)
    label = klass.model_name.human(count: 2)

    if klass.respond_to?(:console_sidebar_count)
      count = klass.console_sidebar_count
      if count != 0
        return "#{label} <strong class=\"font-weight-bold\">(#{count})</strong>"
      end
    end

    label
  end
end
