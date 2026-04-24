# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ai::SuggestionsControllerBaseTest < ActionController::TestCase
  class FakeProviderAdapter
    def generate_suggestions(prompt:, field:, suggestion_count:)
      [
        Folio::Ai::Suggestion.new(key: 1,
                                  text: "Generated text",
                                  meta: { tone_label: "Neutral" }),
      ]
    end
  end

  class TestController < ActionController::Base
    include Folio::Console::Ai::SuggestionsControllerBase

    attr_accessor :site,
                  :user,
                  :context,
                  :host_eligible,
                  :provider_adapter

    def self.controller_path
      "test"
    end

    private
      def folio_ai_site
        site
      end

      def folio_ai_user
        user
      end

      def folio_ai_context
        context || {}
      end

      def folio_ai_host_eligible?
        host_eligible.nil? || host_eligible
      end

      def folio_ai_provider_adapter
        provider_adapter
      end
  end

  setup do
    @controller = TestController.new
    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw do
      post "create" => "test#create"
    end
    @request = ActionDispatch::TestRequest.create
    @response = ActionDispatch::TestResponse.new

    Folio::Ai.reset_registry!
    Folio::Ai.register_integration(:articles, fields: %i[title])

    @site = create_site(force: true)
    @site.update!(ai_settings: enabled_ai_settings)
    @user = create(:folio_user, auth_site: @site)
    @controller.site = @site
    @controller.user = @user
    @controller.provider_adapter = FakeProviderAdapter.new
  end

  teardown do
    Folio::Ai.reset_registry!
  end

  test "returns normalized suggestions" do
    with_config(folio_ai_enabled: true) do
      post :create, params: request_params
    end

    json = JSON.parse(response.body)

    assert_response :success
    assert_equal "Generated text", json.dig("data", "suggestions", 0, "text")
    assert_equal "Neutral", json.dig("data", "suggestions", 0, "meta", "tone_label")
    assert_equal "", json.dig("data", "user_instructions")
  end

  test "rejects globally disabled feature" do
    with_config(folio_ai_enabled: false) do
      post :create, params: request_params
    end

    json = JSON.parse(response.body)

    assert_response :forbidden
    assert_equal "feature_disabled", json["error_code"]
  end

  test "returns prompt_missing when field has no prompt" do
    @site.update!(ai_settings: enabled_ai_settings(prompt: ""))

    with_config(folio_ai_enabled: true) do
      post :create, params: request_params
    end

    json = JSON.parse(response.body)

    assert_response :unprocessable_entity
    assert_equal "prompt_missing", json["error_code"]
  end

  private
    def request_params
      {
        integration_key: "articles",
        field_key: "title",
        instructions: "",
      }
    end

    def enabled_ai_settings(prompt: "Write a title.")
      {
        enabled: true,
        integrations: {
          articles: {
            fields: {
              title: {
                prompt:,
              },
            },
          },
        },
      }
    end
end
