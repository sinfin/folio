# frozen_string_literal: true

class Folio::Console::Accounts::InviteAndCopyCell < Folio::ConsoleCell
  def url
    controller.accept_invitation_url(model,
                                     invitation_token: model.raw_invitation_token,
                                     only_path: false)
  end
end
