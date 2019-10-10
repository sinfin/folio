# frozen_string_literal: true

class Folio::Console::Atoms::LayoutSwitchCell < Folio::ConsoleCell
  def layouts
    %w[vertical horizontal]
  end

  def default_layout
    model.presence || 'vertical'
  end

  def active_class(layout)
    if layout == default_layout
      'f-c-atoms-layout-switch__button--active'
    end
  end
end
