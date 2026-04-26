# frozen_string_literal: true

require "test_helper"

class Folio::Ai::ProviderConfigTest < ActiveSupport::TestCase
  test "uses field provider and model override" do
    site = build(:folio_site)
    site.ai_settings = {
      enabled: true,
      default_provider: "openai",
      default_model: "site-model",
      integrations: {
        articles: {
          fields: {
            title: {
              provider: "anthropic",
              model: "field-model",
            },
          },
        },
      },
    }

    result = Folio::Ai::ProviderConfig.new(site:,
                                           integration_key: :articles,
                                           field_key: :title).call

    assert_equal :anthropic, result.provider
    assert_equal "field-model", result.model
  end

  test "falls back to site defaults before engine defaults" do
    site = build(:folio_site)
    site.ai_settings = {
      enabled: true,
      default_provider: "anthropic",
      default_model: "site-model",
    }

    result = Folio::Ai::ProviderConfig.new(site:,
                                           integration_key: :articles,
                                           field_key: :title).call

    assert_equal :anthropic, result.provider
    assert_equal "site-model", result.model
  end

  test "uses provider default when provider override has no paired model override" do
    site = build(:folio_site)
    site.ai_settings = {
      enabled: true,
      default_provider: "openai",
      default_model: "site-openai-model",
      integrations: {
        articles: {
          fields: {
            title: {
              provider: "anthropic",
            },
          },
        },
      },
    }

    result = Folio::Ai::ProviderConfig.new(site:,
                                           integration_key: :articles,
                                           field_key: :title).call

    assert_equal :anthropic, result.provider
    assert_equal "claude-opus-4-7", result.model
  end

  test "falls back to configured provider model" do
    site = build(:folio_site)
    site.ai_settings = { enabled: true }

    result = Folio::Ai::ProviderConfig.new(site:,
                                           integration_key: :articles,
                                           field_key: :title).call

    assert_equal :openai, result.provider
    assert_equal "gpt-5.5", result.model
  end

  test "rejects unknown provider" do
    site = build(:folio_site)
    site.ai_settings = {
      enabled: true,
      default_provider: "unknown",
    }

    assert_raises(Folio::Ai::UnknownProviderError) do
      Folio::Ai::ProviderConfig.new(site:,
                                    integration_key: :articles,
                                    field_key: :title).call
    end
  end
end
