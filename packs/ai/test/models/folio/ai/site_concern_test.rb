# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")

class Folio::Ai::SiteConcernTest < ActiveSupport::TestCase
  setup do
    Folio::Site.include(Folio::Ai::SiteConcern) unless Folio::Site < Folio::Ai::SiteConcern
    Folio::Site.prepend(Folio::Ai::SiteConsoleTabsExtension) unless Folio::Site < Folio::Ai::SiteConsoleTabsExtension

    Folio::Ai.reset_registry!
  end

  teardown do
    Folio::Ai.reset_registry!
  end

  test "reads site AI settings" do
    site = build(:folio_site,
                 ai_settings: {
                   "enabled" => true,
                   "provider" => "dummy",
                   "model" => "dummy",
                   "integrations" => {
                     "folio_pages" => {
                       "fields" => {
                         "title" => {
                           "prompt" => "Write a short title.",
                         },
                       },
                     },
                   },
                 })

    assert_predicate site, :ai_enabled?
    assert_equal "dummy", site.ai_provider
    assert_equal "dummy", site.ai_model
    assert_equal "Write a short title.",
                 site.ai_prompt_for(record_key: "folio_pages", field_key: "title")
  end

  test "adds AI prompts tab when AI is enabled and records are registered" do
    site = build(:folio_site)

    Folio::Ai.config.stub(:enabled?, true) do
      assert_not_includes site.console_form_tabs, :ai_prompts

      Folio::Ai.register_record(record_class_name: "Folio::Page",
                                fields: [:title])

      assert_includes site.console_form_tabs, :ai_prompts
    end
  end
end
