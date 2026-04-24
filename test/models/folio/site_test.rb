# frozen_string_literal: true

require "test_helper"

module Folio
  class SiteTest < ActiveSupport::TestCase
    test "reads AI prompt settings" do
      site = build(:folio_site)
      site.ai_settings = {
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
      }

      assert site.ai_enabled?
      assert site.ai_prompt_enabled_for?(integration_key: :articles, field_key: :title)
      assert site.ai_field_enabled_for?(integration_key: :articles, field_key: :title)
      assert_equal "Write a title.", site.ai_prompt_for(integration_key: :articles, field_key: :title)
    end

    test "AI prompt is disabled when field is explicitly disabled" do
      site = build(:folio_site)
      site.ai_settings = {
        enabled: true,
        integrations: {
          articles: {
            fields: {
              title: {
                enabled: false,
                prompt: "Write a title.",
              },
            },
          },
        },
      }

      assert_not site.ai_field_enabled_for?(integration_key: :articles, field_key: :title)
      assert_not site.ai_prompt_enabled_for?(integration_key: :articles, field_key: :title)
    end

    test "adds AI prompts tab only when feature is enabled and registry has integrations" do
      Folio::Ai.reset_registry!
      Folio::Ai.register_integration(:articles, fields: %i[title])
      site = build(:folio_site)

      with_config(folio_ai_enabled: true) do
        assert_includes site.console_form_tabs, :ai_prompts
      end
    ensure
      Folio::Ai.reset_registry!
    end

    test "sets AI prompt without losing existing settings" do
      site = build(:folio_site)
      site.ai_settings = { enabled: true }

      site.set_ai_prompt(integration_key: :articles,
                         field_key: :title,
                         prompt: "Write a title.")

      assert site.ai_enabled?
      assert_equal "Write a title.", site.ai_prompt_for(integration_key: :articles, field_key: :title)
    end

    test "normalizes blank AI settings before validation" do
      site = build(:folio_site, ai_settings: nil)

      site.valid?

      assert_equal({}, site.ai_settings)
    end
  end
end

# == Schema Information
#
# Table name: folio_sites
#
#  id                             :integer          not null, primary key
#  title                          :string
#  domain                         :string
#  email                          :string
#  phone                          :string
#  locale                         :string           default("en")
#  locales                        :string           default([]), is an Array
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  google_analytics_tracking_code :string
#  facebook_pixel_code            :string
#  social_links                   :json
#  address                        :text
#  description                    :text
#
# Indexes
#
#  index_folio_sites_on_domain  (domain)
#
