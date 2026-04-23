# frozen_string_literal: true

require "test_helper"

class Folio::Ai::AvailabilityTest < ActiveSupport::TestCase
  setup do
    @site = create_site(force: true)
    Folio::Ai.reset_registry!
    Folio::Ai.register_integration(:articles, fields: %i[title perex])
  end

  teardown do
    Folio::Ai.reset_registry!
  end

  test "is unavailable when global feature is disabled" do
    @site.ai_settings = enabled_settings

    result = Folio::Ai::Availability.new(site: @site,
                                         integration_key: :articles,
                                         field_key: :title,
                                         global_enabled: false).call

    assert_not result.available?
    assert_equal :global_disabled, result.reason
  end

  test "is unavailable when site is disabled" do
    @site.ai_settings = enabled_settings(enabled: false)

    result = availability.call

    assert_not result.available?
    assert_equal :site_disabled, result.reason
  end

  test "is unavailable when field is unknown" do
    @site.ai_settings = enabled_settings

    result = Folio::Ai::Availability.new(site: @site,
                                         integration_key: :articles,
                                         field_key: :unknown,
                                         global_enabled: true).call

    assert_not result.available?
    assert_equal :field_not_registered, result.reason
  end

  test "is unavailable when prompt is blank" do
    @site.ai_settings = enabled_settings(prompt: "")

    result = availability.call

    assert_not result.available?
    assert_equal :prompt_missing, result.reason
  end

  test "is unavailable when host rejects field" do
    @site.ai_settings = enabled_settings

    result = Folio::Ai::Availability.new(site: @site,
                                         integration_key: :articles,
                                         field_key: :title,
                                         host_eligible: false,
                                         global_enabled: true).call

    assert_not result.available?
    assert_equal :host_ineligible, result.reason
  end

  test "is available when all gates pass" do
    @site.ai_settings = enabled_settings

    result = availability.call

    assert result.available?
    assert_equal "title", result.field.key
  end

  private
    def availability
      Folio::Ai::Availability.new(site: @site,
                                  integration_key: :articles,
                                  field_key: :title,
                                  global_enabled: true)
    end

    def enabled_settings(enabled: true, prompt: "Write a title")
      {
        enabled:,
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
