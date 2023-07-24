# frozen_string_literal: true

class Folio::Console::Ui::NotificationModalCell < Folio::ConsoleCell
  CLASS_NAME_BASE = "f-c-ui-notification-modal"
  CLASS_NAME = ".#{CLASS_NAME_BASE}"

  def show
    cell("folio/console/modal", class: CLASS_NAME_BASE,
                                footer: "{footer}",
                                body: "{body}",
                                title: "{title}",
                                data:)
  end

  def data
    {
      controller: "f-c-ui-notification-modal",
      action: "f-c-ui-notification-modal-trigger:trigger->f-c-ui-notification-modal#onTrigger"
    }
  end
end
