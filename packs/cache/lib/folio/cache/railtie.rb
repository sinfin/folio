# frozen_string_literal: true

require_relative "../../../app/helpers/folio/cache/helper"

module Folio
  module Cache
    class Railtie < ::Rails::Railtie
      config.to_prepare do
        Folio::Ability.class_eval do
          def folio_cache_pack_rules
            if user&.superadmin?
              can :manage, Folio::Cache::Version
            end
          end
        end

        Folio::Site.class_eval do
          def self.console_sidebar_before_site_packs_links(pack_name)
            if pack_name == :cache
              ["Folio::Cache::Version"]
            else
              super
            end
          end
        end

        Folio::Publishable::Basic.include(Folio::Cache::PublishableExtension)
        Folio::Publishable::WithDate.include(Folio::Cache::PublishableWithDateExtension)
        Folio::Publishable::Within.include(Folio::Cache::PublishableWithinExtension)
        Folio::Current.include(Folio::Cache::CurrentConcern)
        Folio::ApplicationRecord.include(Folio::Cache::ModelConcern)
        Folio::ApplicationComponent.include(Folio::Cache::Helper)
      end

      initializer "folio_cache.helpers" do
        ActiveSupport.on_load(:action_view) do
          include Folio::Cache::Helper
        end
      end
    end
  end
end
