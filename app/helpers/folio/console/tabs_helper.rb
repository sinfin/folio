# frozen_string_literal: true

module Folio::Console::TabsHelper
  def tabs(keys)
    if keys.present? && keys.size > 1
      if keys.include?(params[:tab].try(:to_sym))
        @folio_active_tab = params[:tab].try(:to_sym)
      end

      ary = keys.map do |key|
        hash = if key.is_a?(Hash)
          key
        else
          { key: }
        end

        @folio_active_tab ||= key

        {
          label: t("folio.console.tabs.#{hash[:key]}", default: @klass.try(:human_attribute_name, hash[:key]) || hash[:key]),
          active: @folio_active_tab == hash[:key],
        }.merge(hash)
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
