# frozen_string_literal: true

module Folio
  module Ai
    class Railtie < ::Rails::Railtie
      config.to_prepare do
        next unless Folio.pack_enabled?(:ai)

        Folio::Site.include(Folio::Ai::SiteConcern) unless Folio::Site < Folio::Ai::SiteConcern
        Folio::Site.prepend(Folio::Ai::SiteConsoleTabsExtension) unless Folio::Site < Folio::Ai::SiteConsoleTabsExtension
        Folio::User.include(Folio::Ai::UserConcern) unless Folio::User < Folio::Ai::UserConcern

        unless Folio::Console::SitesController < Folio::Ai::SitesControllerConcern
          Folio::Console::SitesController.prepend(Folio::Ai::SitesControllerConcern)
        end

        unless Folio::Console::FormsHelper < Folio::Ai::FormsHelper
          Folio::Console::FormsHelper.include(Folio::Ai::FormsHelper)
        end
      end
    end
  end
end
