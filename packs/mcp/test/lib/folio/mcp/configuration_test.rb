# frozen_string_literal: true

require "test_helper"

class Folio::Mcp::ConfigurationTest < ActiveSupport::TestCase
  setup do
    Folio::Mcp.reset_configuration!
  end

  teardown do
    Folio::Mcp.reset_configuration!
  end

  test "default configuration" do
    config = Folio::Mcp.configuration

    assert_equal({}, config.resources)
    assert_equal [:en], config.locales
    assert_equal 100, config.rate_limit
    assert_nil config.audit_logger
  end

  test "configure with hash resources" do
    Folio::Mcp.configure do |config|
      config.resources = {
        pages: {
          model: "Folio::Page",
          fields: %i[title slug],
          tiptap_fields: %i[tiptap_content]
        }
      }
      config.locales = %i[cs en]
    end

    assert_equal "Folio::Page", Folio::Mcp.configuration.resources[:pages][:model]
    assert_equal %i[title slug], Folio::Mcp.configuration.resources[:pages][:fields]
  end

  test "configure with block resources" do
    Folio::Mcp.configure do |config|
      config.resource :pages do
        model "Folio::Page"
        fields %i[title slug perex]
        tiptap_fields %i[tiptap_content]
        cover_field :cover
        allowed_types %w[Folio::Page]
      end
    end

    config = Folio::Mcp.configuration.resources[:pages]

    assert_equal "Folio::Page", config[:model]
    assert_equal %i[title slug perex], config[:fields]
    assert_equal %i[tiptap_content], config[:tiptap_fields]
    assert_equal :cover, config[:cover_field]
    assert_equal %w[Folio::Page], config[:allowed_types]
  end

  test "configured? returns false without resources" do
    assert_not Folio::Mcp.configured?
  end

  test "configured? returns true with resources" do
    Folio::Mcp.configure do |config|
      config.resources = { pages: { model: "Folio::Page" } }
    end

    assert Folio::Mcp.configured?
  end

  test "audit_logger can be set" do
    logs = []
    Folio::Mcp.configure do |config|
      config.audit_logger = ->(event) { logs << event }
    end

    Folio::Mcp.configuration.audit_logger.call({ action: "test" })
    assert_equal [{ action: "test" }], logs
  end
end
