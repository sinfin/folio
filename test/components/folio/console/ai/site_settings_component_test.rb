# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ai::SiteSettingsComponentTest < Folio::Console::ComponentTest
  setup do
    Folio::Ai.reset_registry!
    Folio::Ai.register_integration(:articles,
                                   label: "Articles",
                                   fields: [
                                     Folio::Ai::Field.new(key: :title,
                                                          label: "Title",
                                                          character_limit: 120),
                                   ])
  end

  teardown do
    Folio::Ai.reset_registry!
  end

  def test_render
    site = build(:folio_site, ai_settings: {
                   enabled: true,
                   integrations: {
                     articles: {
                       fields: {
                         title: {
                           prompt: "Write a title.",
                         },
                       },
                     },
                   },
                 })

    with_config(folio_ai_enabled: true) do
      vc_test_controller.view_context.simple_form_for(site, url: "/") do |form|
        render_inline(Folio::Console::Ai::SiteSettingsComponent.new(form:))
      end
    end

    assert_selector(".f-c-ai-site-settings")
    assert_selector("input[name$='[ai_settings][enabled]'][value='1']", visible: :all)
    assert_selector("textarea[name$='[fields][title][prompt]']", text: "Write a title.")
    assert_text("Limit: 120")
  end

  def test_does_not_render_when_ai_is_disabled
    site = build(:folio_site)

    with_config(folio_ai_enabled: false) do
      vc_test_controller.view_context.simple_form_for(site, url: "/") do |form|
        render_inline(Folio::Console::Ai::SiteSettingsComponent.new(form:))
      end
    end

    assert_no_selector(".f-c-ai-site-settings")
  end
end
