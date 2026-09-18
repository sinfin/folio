# frozen_string_literal: true

class Folio::Console::Ui::PagyComponent < Folio::Console::ApplicationComponent
  bem_class_name :no_margin, :index_header

  def initialize(pagy:,
                 options: nil,
                 no_margin: false,
                 index_header: false)
    @pagy = pagy
    @options = options || {}
    @no_margin = no_margin
    @index_header = index_header
  end

  def render?
    @pagy.present?
  end

  def link
    @link ||= @pagy.send(:a_lambda)
  end

  def series
    @pagy.send(:series)
  end

  def middle_component?
    @options[:middle_component].present?
  end

  def middle_component
    @options[:middle_component].call
  end

  def icon(code)
    folio_icon(code, class: "f-c-ui-pagy__ico")
  end

  def data
    if @options && @options[:reload_url]
      stimulus_controller("f-c-ui-pagy",
                          values: { reload_url: @options[:reload_url] },
                          action: { "f-c-ui-pagy/reload" => "reload" })
    end
  end

  def page_class(item)
    if item < @pagy.page
      "f-c-ui-pagy__page--page-minus-#{@pagy.page - item}"
    elsif item > @pagy.page
      "f-c-ui-pagy__page--page-plus-#{item - @pagy.page}"
    end
  end
end
