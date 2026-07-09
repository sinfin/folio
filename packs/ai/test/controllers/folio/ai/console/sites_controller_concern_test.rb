# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")

class Folio::Ai::Console::SitesControllerConcernTest < Folio::Console::BaseControllerTest
  setup do
    Folio::Site.include(Folio::Ai::SiteConcern) unless Folio::Site < Folio::Ai::SiteConcern

    unless Folio::Console::SitesController < Folio::Ai::SitesControllerConcern
      Folio::Console::SitesController.prepend(Folio::Ai::SitesControllerConcern)
    end
  end

  test "permits AI settings on site update" do
    Folio::Ai.config.stub(:enabled?, true) do
      put console_site_path,
          params: {
            site: {
              ai_settings: {
                enabled: "1",
                provider: "dummy",
                model: "dummy",
                integrations: {
                  folio_pages: {
                    fields: {
                      title: {
                        enabled: "0",
                      },
                    },
                    groups: {
                      meta: {
                        enabled: "1",
                      },
                    },
                  },
                },
              },
            },
          }
    end

    settings = @site.reload.ai_settings_data

    assert_equal "1", settings["enabled"]
    assert_equal "dummy", settings["provider"]
    assert_equal "dummy", settings["model"]
    assert_equal "0", settings.dig("integrations", "folio_pages", "fields", "title", "enabled")
    assert_equal "1", settings.dig("integrations", "folio_pages", "groups", "meta", "enabled")
  end
end
