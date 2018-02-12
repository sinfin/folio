# frozen_string_literal: true

module Folio
  module Console::BaseHelper
    def icon(name, title = nil)
      classes = ['fa', "fa-#{name}"]
      classes << 'fa-mr' if title.present?
      i = %{<i class="#{classes.join(' ')}"></i>}
      [i, title].compact.join(' ').html_safe
    end

    def featured_button(bool)
      button_tag(class: 'btn btn-sm btn-transparent node') do
        featured_icon(bool)
      end
    end

    def published_button(bool)
      button_tag(class: 'btn btn-sm btn-transparent node') do
        on_off_icon(bool)
      end
    end

    def add_action_breadcrumb
      return if action_name == 'index'
      name = add_action_breadcrumb_name
      add_breadcrumb I18n.t("folio.console.breadcrumbs.actions.#{name}")
    end

    private

      def add_action_breadcrumb_name
        case action_name
        when 'update'
          'edit'
        when 'create'
          'new'
        else
          action_name
        end
      end
  end
end
