# frozen_string_literal: true

class Folio::Console::Users::HeaderActionsCell < Folio::ConsoleCell
  def buttons_model
    buttons = []
    if can_now?(:impersonate, model)
      buttons << {
          href: url_for([:impersonate, :console, model]),
          target: "_blank",
          confirm: true,
          icon: :face,
          label: t(".impersonate"),
          variant: :info,
        }
    end
    buttons << {
        href: url_for([:send_reset_password_email, :console, model]),
        confirm: true,
        icon: :lock,
        label: t(".send_reset_password_email"),
        variant: :warning,
      }
    buttons
  end
end
