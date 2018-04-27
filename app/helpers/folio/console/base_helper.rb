# frozen_string_literal: true

module Folio
  module Console::BaseHelper
    def icon(name, title = nil)
      classes = ['fa', "fa-#{name}"]
      classes << 'fa-mr' if title.present?
      i = %{<i class="#{classes.join(' ')}"></i>}
      [i, title].compact.join(' ').html_safe
    end

    def add_action_breadcrumb(title = false)
      return if action_name == 'index'
      if title
        add_breadcrumb title
      else
        name = add_action_breadcrumb_name
        add_breadcrumb I18n.t("folio.console.breadcrumbs.actions.#{name}")
      end
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
