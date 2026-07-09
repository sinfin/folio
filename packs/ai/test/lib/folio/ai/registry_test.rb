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
                             ],
                             groups: [
                               {
                                 key: :meta,
                                 label: "Meta",
                                 fields: %i[title slug],
                               },
                               {
                                 key: :seo,
                                 fields: %i[title],
                               },
                             ])

    record = registry.record("folio_pages")

    assert_equal "folio_pages", record[:key]
    assert_equal "Folio::Page", record[:record_class_name]
    assert_nil record[:label]
    assert_nil registry.field("folio_pages", :title)[:label]
    assert_nil registry.field("folio_pages", :title)[:character_limit]
    assert_equal "Slug", registry.field("folio_pages", :slug)[:label]
    assert_equal 120, registry.field("folio_pages", :slug)[:character_limit]
    assert_equal "Meta", registry.group("folio_pages", :meta)[:label]
    assert_equal %w[title slug], registry.group("folio_pages", :meta)[:fields]
    assert_nil registry.group("folio_pages", :seo)[:label]
    assert_equal %w[title], registry.group("folio_pages", :seo)[:fields]
  end

  test "rejects invalid record classes and duplicate fields or groups" do
    registry = Folio::Ai::Registry.new

    assert_raises(ArgumentError) do
      registry.register_record(record_class_name: "Missing", fields: [:title])
    end

    assert_raises(ArgumentError) do
      registry.register_record(record_class_name: "Folio::Page", fields: %i[title title])
    end

    assert_raises(ArgumentError) do
      registry.register_record(record_class_name: "Folio::Page",
                               fields: %i[title],
                               groups: [{ key: :meta, fields: %i[missing] }])
    end

    assert_raises(ArgumentError) do
      registry.register_record(record_class_name: "Folio::Page",
                               fields: %i[title],
                               groups: [{ key: :title, fields: %i[title] }])
    end
  end
end
