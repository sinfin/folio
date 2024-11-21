# frozen_string_literal: true

class Dummy::Ui::MiniSelectComponent < ApplicationComponent
  bem_class_name :verbose

  def initialize(type: :language, options: nil, verbose: false, icon: nil, toggle_select: false)
    @type = type
    @options = options
    @verbose = verbose
    @icon = icon
    @toggle_select = toggle_select
  end

  def options
    if @options.nil?
      @options = if @type == :language
        Folio::Current.site.locales.map do |locale|
          label = t(".language/#{@verbose ? "verbose" : "default"}/#{locale}")
          { href: controller.main_app.root_path(locale:), label:, selected: locale == I18n.locale.to_s }
        end
      elsif @type == :currency
        %w[czk usd eur].each_with_index.map do |currency, i|
          label = t(".currency/#{@verbose ? "verbose" : "default"}/#{currency}")
          { href: controller.main_app.root_path(currency:), label:, selected: i.zero? }
        end
      end
    else
      @options
    end
  end

  def selected_value_with_fallback
    @options.find { |o| o[:selected] } || @options.first
  end

  def data
    stimulus_controller("d-ui-mini-select", values: {
      type: @type,
      options:,
      toggle_select: @toggle_select
    })
  end

  def stimulus_option_a_data
    @stimulus_option_a_data ||= stimulus_data(action: {
      "click" => "optionClick",
      "keydown.enter" => "optionClick",
    }, target: "option")
  end
end
