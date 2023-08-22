# frozen_string_literal: true

module Dummy::UiHelper
  def dummy_ui_primary_button(**kwargs)
    render(Dummy::Ui::ButtonComponent.new(variant: :primary,
                                          size:,
                                          confirm:,
                                          class_name:,
                                          label:,
                                          hide_label_on_mobile:,
                                          modal:,
                                          icon:,
                                          right_icon:,
                                          loader:,
                                          data:,
                                          tag:,
                                          type:))
  end

  def dummy_ui_button(variant: "primary",
                      size: nil,
                      confirm: false,
                      class_name: nil,
                      label: nil,
                      hide_label_on_mobile: false,
                      modal: nil,
                      icon: nil,
                      right_icon: nil,
                      loader: false,
                      data: {},
                      tag: :button,
                      type: :button)
    render(Dummy::Ui::ButtonComponent.new(variant:,
                                          size:,
                                          confirm:,
                                          class_name:,
                                          label:,
                                          hide_label_on_mobile:,
                                          modal:,
                                          icon:,
                                          right_icon:,
                                          loader:,
                                          data:,
                                          tag:,
                                          type:))
  end

  def dummy_ui_buttons(buttons:, class_name: nil, nowrap: false, vertical: false)
    render(Dummy::Ui::ButtonsComponent.new(buttons:, class_name:, nowrap:, vertical:))
  end

  def dummy_ui_icon(name, class_name: nil, width: nil, height: nil, top: nil, data: nil, title: nil)
    render(Dummy::Ui::IconComponent.new(name:,
                                        class_name:,
                                        width:,
                                        height:,
                                        top:,
                                        data:,
                                        title:))
  end
end
