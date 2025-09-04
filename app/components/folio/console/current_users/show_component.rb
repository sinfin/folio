# frozen_string_literal: true

class Folio::Console::CurrentUsers::ShowComponent < Folio::Console::ApplicationComponent
  def initialize(user:)
    @user = user
  end

  def edit_button_model(label: nil)
    {
      class_name: "f-c-current-users-show__edit-btn",
      variant: :gray,
      data: stimulus_action(click: "edit"),
      label: label || t("folio.console.actions.edit")
    }
  end

  def form_buttons_model(edit_label: nil)
    [
      {
        label: t("folio.console.actions.cancel"),
        type: :button,
        variant: :gray,
        data: stimulus_action(click: "cancel")
      },
      {
        label: t("folio.console.actions.save"),
        type: :submit
      },
    ]
  end

  def data
    stimulus_controller("f-c-current-users-show")
  end
end
