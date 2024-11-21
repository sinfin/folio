# frozen_string_literal: true

class Folio::Console::Users::InviteAndCopyCell < Folio::ConsoleCell
  def url
    args = {
      invitation_token: model.raw_invitation_token,
      only_path: false,
    }

    if Folio::Current.enabled_site_for_crossdomain_devise
      args[:host] = Folio::Current.enabled_site_for_crossdomain_devise.env_aware_domain
    end

    controller.accept_invitation_url(model, args)
  end
end
