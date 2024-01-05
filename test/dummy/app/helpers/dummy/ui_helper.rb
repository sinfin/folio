# frozen_string_literal: true

module Dummy::UiHelper
  def dummy_ui_button(**kwargs)
    render(Dummy::Ui::ButtonComponent.new(**kwargs))
  end

  def dummy_ui_buttons(**kwargs)
    render(Dummy::Ui::ButtonsComponent.new(**kwargs))
  end

  def dummy_ui_icon(name, **kwargs)
    render(Dummy::Ui::IconComponent.new(name:, **kwargs))
  end

  def dummy_ui_image(placement, size, **kwargs)
    render(Dummy::Ui::ImageComponent.new(placement:, size:, **kwargs))
  end

  def dummy_ui_tabs(**kwargs)
    render(Dummy::Ui::TabsComponent.new(**kwargs))
  end

end
