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
         (class_name[:klass] || class_name[:label]) &&
         class_name[:path]

        label = if class_name[:label]
          t(".#{class_name[:label]}")
        elsif class_name[:klass]
          label_from(class_name[:klass].constantize)
        else
          ''
        end

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

        if class_name[:icon]
          link(nil, path) do
            concat(content_tag(:i, '', class: "#{class_name[:icon]} f-c-layout-sidebar__icon"))
            concat(label)
          end
        else
          link(label, path, paths: paths)
        end
      else
        klass = class_name.constantize

        label = label_from(klass)
        path = controller.url_for([:console, klass])
        link(label, path)
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
      [
        'Folio::Account',
        {
          klass: 'Folio::Site',
          icon: 'fa fa-cogs',
          path: :console_site_path,
          label: 'settings'
        },
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
