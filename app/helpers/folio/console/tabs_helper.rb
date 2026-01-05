# frozen_string_literal: true

module Folio::Console::TabsHelper
  def tabs(keys)
    if keys.present? && keys.size > 1
      if keys.include?(params[:tab].try(:to_sym))
        @folio_active_tab = params[:tab].try(:to_sym)
      end

      if @folio_active_tab.nil? && respond_to?(:controller)
        cookies = controller.send(:cookies)

        if cookies && cookies["f-c-ui-tabs__selected-tab"].present?
          @folio_active_tab = cookies["f-c-ui-tabs__selected-tab"].try(:to_sym).presence
        end
      end

      ary = keys.map do |key|
        hash = if key.is_a?(Hash)
          key
        else
          { key: }
        end

        unless hash[:hidden]
          @folio_active_tab ||= key
        end

        {
          label: t("folio.console.tabs.#{hash[:key]}", default: @klass.try(:human_attribute_name, hash[:key]) || hash[:key]),
          active: !hash[:hidden] && @folio_active_tab == hash[:key],
        }.merge(hash)
      end

      if ary.none? { |hash| hash[:active] }
        ary.each do |hash|
          unless hash[:hidden]
            hash[:active] = true
            @folio_active_tab = hash[:key]
            break
          end
        end
      end

      render(Folio::Console::Ui::TabsComponent.new(tabs: ary,
                                                   use_cookies_for_active: true))
    end
  end

  def tab(key, active: false, &block)
    if active || (key == :content && !@folio_active_tab)
      @folio_active_tab = key
    end

    active = @folio_active_tab == key

    render(Folio::Console::Ui::Tabs::TabPaneComponent.new(active:, key:), &block)
  end
end
