# frozen_string_literal: true

class Dummy::Ui::MiniSelectComponent < ApplicationComponent
  bem_class_name :verbose

  def initialize(type: :language, options: nil, selected_value: nil, verbose: false, icon: nil)
    @type = type
    @options = options
    @selected_value = selected_value
    @verbose = verbose
    @icon = icon
  end

  def options
    if @options.nil?
      if @type == :language
        @verbose ? ["Czech", "English", "German"] : ["CS", "EN", "DE"]
      elsif @type == :currency
        @verbose ? ["Kč", "Euro", "USD"] : ["$", "€"]
      end
    else
      @options
    end
  end

  def selected_value
    @selected_value.nil? ? options.first.to_s : @selected_value
  end

  def toggle_select
    options.count <= 2
  end

  def data
    stimulus_controller("d-ui-mini-select", values: {
      type: @type,
      options:,
      toggle_select:
    })
  end
end