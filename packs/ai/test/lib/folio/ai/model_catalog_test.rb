# frozen_string_literal: true

require "test_helper"

class Folio::Ai::ModelCatalogTest < ActiveSupport::TestCase
  test "uses configured default without fetching provider models" do
    stub_request(:get, "https://api.openai.com/v1/models")
      .to_return(body: {
        data: [{ id: "gpt-live", created: 1 }],
      }.to_json)

    catalog = Folio::Ai::ModelCatalog.new(provider: :openai, api_key: "secret")

    with_provider_models_env_values({}) do
      with_ai_config(provider_models: { openai: "gpt-5.5" }) do
        result = catalog.result(selected: "site-model")

        assert_not result.verified?
        assert_equal ["gpt-5.5", "site-model"], result.models.map(&:id)
        assert result.models.last.available?
      end
    end

    assert_not_requested :get, "https://api.openai.com/v1/models"
  end

  test "adds provider models from env" do
    catalog = Folio::Ai::ModelCatalog.new(provider: :openai, api_key: "secret")

    with_provider_models_env_values(openai: "gpt-5.5-pro, gpt-5.5-mini") do
      with_ai_config(provider_models: { openai: "gpt-5.5" }) do
        result = catalog.result

        assert_equal %w[gpt-5.5 gpt-5.5-pro gpt-5.5-mini], result.models.map(&:id)
      end
    end
  end

  test "normalizes provider model env ids" do
    catalog = Folio::Ai::ModelCatalog.new(provider: :openai, api_key: "secret")

    with_provider_models_env_values(openai: " gpt-5.5 , , gpt-5.5-pro, gpt-5.5-pro ") do
      with_ai_config(provider_models: { openai: "gpt-5.5" }) do
        result = catalog.result

        assert_equal %w[gpt-5.5 gpt-5.5-pro], result.models.map(&:id)
      end
    end
  end

  test "uses provider model options as metadata" do
    catalog = Folio::Ai::ModelCatalog.new(provider: :openai, api_key: "secret")

    with_provider_models_env_values(openai: "gpt-5.5-pro") do
      with_ai_config(provider_models: { openai: "gpt-5.5" },
                     provider_model_options: {
                       openai: {
                         "gpt-5.5" => { label: "gpt-5.5" },
                         "gpt-5.5-pro" => { label: "GPT 5.5 Pro", cost_tier: "premium" },
                       },
                     }) do
        result = catalog.result

        assert_equal ["gpt-5.5", "GPT 5.5 Pro - Premium - gpt-5.5-pro"],
                     result.models.map(&:select_label)
      end
    end
  end

  private
    def with_provider_models_env_values(values, &)
      Folio::Ai.stub(:provider_models_env_values, values, &)
    end
end
