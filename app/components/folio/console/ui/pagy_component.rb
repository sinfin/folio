# frozen_string_literal: true

class Folio::Console::Ui::PagyComponent < Folio::Console::ApplicationComponent
  include Pagy::Frontend

  def initialize(pagy:, options: nil)
    @pagy = pagy
    @options = options || {}
  end

  def render?
    @pagy.present?
  end

  def link
    @link ||= pagy_anchor(@pagy)
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
end
