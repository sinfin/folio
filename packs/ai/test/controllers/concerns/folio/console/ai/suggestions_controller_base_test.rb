# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ai::SuggestionsControllerBaseTest < ActionController::TestCase
  class FakeProviderAdapter
    attr_reader :calls

    def initialize
      @calls = []
    end

    def generate_suggestions(prompt:, field:, suggestion_count:)
      calls << {
        prompt:,
        field:,
        suggestion_count:,
      }

      [
        Folio::Ai::Suggestion.new(key: 1,
                                  text: "Generated text",
                                  meta: { tone_label: "Neutral" }),
      ]
    end
  end

  class RaisingProviderAdapter
    def initialize(error)
      @error = error
    end

    def generate_suggestions(prompt:, field:, suggestion_count:)
      raise @error
    end
  end

  class TestController < ActionController::Base
    include Folio::Console::Ai::SuggestionsControllerBase

    attr_accessor :site,
                  :user,
                  :context,
                  :context_calls,
                  :snapshot_context,
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
        self.context_calls = context_calls.to_i + 1

        return { snapshot: folio_ai_current_form_snapshot } if snapshot_context

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
    @controller.context_calls = 0
  end

  teardown do
    Folio::Ai.reset_registry!
  end

  test "returns normalized suggestions" do
    with_ai_config(enabled: true) do
      post :create, params: request_params
    end

    json = JSON.parse(response.body)

    assert_response :success
    assert_equal "Generated text", json.dig("data", "suggestions", 0, "text")
    assert_equal "Neutral", json.dig("data", "suggestions", 0, "meta", "tone_label")
    assert_equal "", json.dig("data", "user_instructions")
  end

  test "rejects globally disabled feature" do
    with_ai_config(enabled: false) do
      post :create, params: request_params
    end

    json = JSON.parse(response.body)

    assert_response :forbidden
    assert_equal "feature_disabled", json["error_code"]
  end

  test "returns prompt_missing when field has no prompt" do
    @site.update!(ai_settings: enabled_ai_settings(prompt: ""))

    with_ai_config(enabled: true) do
      post :create, params: request_params
    end

    json = JSON.parse(response.body)

    assert_response :unprocessable_entity
    assert_equal "prompt_missing", json["error_code"]
  end

  test "does not build context when host is ineligible" do
    @controller.host_eligible = false

    with_ai_config(enabled: true) do
      post :create, params: request_params
    end

    json = JSON.parse(response.body)

    assert_response :unprocessable_entity
    assert_equal "host_ineligible", json["error_code"]
    assert_equal 0, @controller.context_calls
  end

  test "exposes sanitized current form snapshot to context builders" do
    @controller.snapshot_context = true

    with_ai_config(enabled: true) do
      post :create, params: request_params.merge(current_form_snapshot: {
        "article[title]" => "Draft title",
        "article[tag_ids][]" => %w[1 2],
        "article[nested]" => { invalid: "ignored" },
      }), as: :json
    end

    prompt = @controller.provider_adapter.calls.first[:prompt]

    assert_response :success
    assert_includes prompt, '"article[title]": "Draft title"'
    assert_includes prompt, '"article[tag_ids][]": ['
    assert_not_includes prompt, "ignored"
  end

  test "returns gateway timeout when provider times out" do
    @controller.provider_adapter = RaisingProviderAdapter.new(Folio::Ai::ProviderTimeoutError.new("timeout"))

    with_ai_config(enabled: true) do
      post :create, params: request_params
    end

    json = JSON.parse(response.body)

    assert_response :gateway_timeout
    assert_equal "provider_timeout", json["error_code"]
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
