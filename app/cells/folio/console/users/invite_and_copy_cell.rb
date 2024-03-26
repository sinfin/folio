# frozen_string_literal: true

class Folio::Console::Users::InviteAndCopyCell < Folio::ConsoleCell
  def url
    args = {
      invitation_token: model.raw_invitation_token,
      only_path: false,
    }

    if ::Rails.application.config.folio_crossdomain_devise && Folio.site_for_crossdomain_devise
      args[:host] = Folio.site_for_crossdomain_devise.env_aware_domain
    end

    controller.accept_invitation_url(model, args)
  end
end
