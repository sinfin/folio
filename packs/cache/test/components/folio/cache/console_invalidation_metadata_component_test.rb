# frozen_string_literal: true

require "test_helper"

class Folio::Cache::ConsoleInvalidationMetadataComponentTest < Folio::ComponentTest
  def test_render
    metadata = { "type" => "manual", "user_name" => "Test User" }

    render_inline(Folio::Cache::ConsoleInvalidationMetadataComponent.new(metadata:))

    assert_selector(".f-cache-console-invalidation-metadata")
  end

  def test_render_with_model_metadata
    metadata = { "type" => "model", "class" => "Folio::Page", "id" => 123 }

    render_inline(Folio::Cache::ConsoleInvalidationMetadataComponent.new(metadata:))

    assert_selector(".f-cache-console-invalidation-metadata")
  end

  def test_render_with_empty_metadata
    render_inline(Folio::Cache::ConsoleInvalidationMetadataComponent.new(metadata: nil))

    assert_no_selector(".f-cache-console-invalidation-metadata")
  end
end
