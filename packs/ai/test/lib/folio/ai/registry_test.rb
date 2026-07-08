# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")

class Folio::Ai::RegistryTest < ActiveSupport::TestCase
  test "registers records by table name" do
    registry = Folio::Ai::Registry.new

    registry.register_record(record_class_name: "Folio::Page",
                             fields: [
                               :title,
                               { key: :slug, label: "Slug", character_limit: 120 },
                             ])

    record = registry.record("folio_pages")

    assert_equal "folio_pages", record[:key]
    assert_equal "Folio::Page", record[:record_class_name]
    assert_equal Folio::Page.model_name.human(count: 2), record[:label]
    assert_equal Folio::Page.human_attribute_name("title"),
                 registry.field("folio_pages", :title)[:label]
    assert_nil registry.field("folio_pages", :title)[:character_limit]
    assert_equal "Slug", registry.field("folio_pages", :slug)[:label]
    assert_equal 120, registry.field("folio_pages", :slug)[:character_limit]
  end

  test "rejects invalid record classes and duplicate fields" do
    registry = Folio::Ai::Registry.new

    assert_raises(ArgumentError) do
      registry.register_record(record_class_name: "Missing", fields: [:title])
    end

    assert_raises(ArgumentError) do
      registry.register_record(record_class_name: "Folio::Page", fields: %i[title title])
    end
  end
end
