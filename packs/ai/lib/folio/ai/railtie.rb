# frozen_string_literal: true

module Folio
  module Ai
    class Railtie < ::Rails::Railtie
      config.to_prepare do
        if defined?(Folio::Site) && !(Folio::Site < Folio::Ai::SiteConcern)
          Folio::Site.include(Folio::Ai::SiteConcern)
        end

        if defined?(Folio::User) && !(Folio::User < Folio::Ai::UserConcern)
          Folio::User.include(Folio::Ai::UserConcern)
        end
      end
    end
  end
end
