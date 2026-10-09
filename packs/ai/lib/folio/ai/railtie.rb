# frozen_string_literal: true

# Attaches AI site and user concerns when the pack is loaded.
module Folio
  module Ai
    class Railtie < ::Rails::Railtie
      config.to_prepare do
        if defined?(Folio::Site) && !(Folio::Site < Folio::Ai::SiteConcern)
          Folio::Site.include(Folio::Ai::SiteConcern)
        end

        if defined?(Folio::Site) && !(Folio::Site < Folio::Ai::SiteConsoleTabsExtension)
          Folio::Site.prepend(Folio::Ai::SiteConsoleTabsExtension)
        end

        if defined?(Folio::User) && !(Folio::User < Folio::Ai::UserConcern)
          Folio::User.include(Folio::Ai::UserConcern)
        end

        if defined?(Folio::Console::SitesController) &&
           !(Folio::Console::SitesController < Folio::Ai::SitesControllerConcern)
          Folio::Console::SitesController.prepend(Folio::Ai::SitesControllerConcern)
        end
      end
    end
  end
end
