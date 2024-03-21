# frozen_string_literal: true

module Folio::Console::TabsHelper
  def tabs(keys)
    if keys.present? && keys.size > 1
      if keys.include?(params[:tab].try(:to_sym))
        @folio_active_tab = params[:tab].try(:to_sym)
      end

      ary = keys.map do |key|
        @folio_active_tab ||= key

        {
          label: t("folio.console.tabs.#{key}", default: @klass.try(:human_attribute_name, key)),
          active: @folio_active_tab == key,
          key:,
        }
      end

      render(Folio::Console::Ui::TabsComponent.new(tabs: ary, remember: "console"))
    end
  end

  def tab(key, active: false, &block)
    if active || (key == :content && !@folio_active_tab)
      @folio_active_tab = key
    end

    active = @folio_active_tab == key

    content_tag(:div, class: "tab-pane #{active ? 'active' : ''}",
                      id: "tab-#{key}",
                      &block)
  end
end
