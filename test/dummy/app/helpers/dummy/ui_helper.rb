# frozen_string_literal: true

module Dummy::UiHelper
  def dummy_ui_button(**kwargs)
    render(Dummy::Ui::ButtonComponent.new(**kwargs))
  end

  def dummy_ui_buttons(**kwargs)
    render(Dummy::Ui::ButtonsComponent.new(**kwargs))
  end

  def dummy_ui_icon(name, opts = {})
    cell("folio/ui/icon", name, opts).show.try(:html_safe)
  end
end
