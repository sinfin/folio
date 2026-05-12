# frozen_string_literal: true

require "test_helper"

class Folio::Ai::RegistryTest < ActiveSupport::TestCase
  test "registers integration fields" do
    registry = Folio::Ai::Registry.new

    registry.register_integration(key: :articles,
                                  record_class_name: "Folio::Page",
                                  fields: [
                                    :title,
                                    { key: :perex, character_limit: 400, auto_attach: true },
                                  ])

    assert registry.field_registered?(:articles, :title)
    assert registry.field_registered?("articles", "perex")
    assert registry.field(:articles, :perex).auto_attach?
    assert_equal 400, registry.field(:articles, :perex).character_limit
  end

  test "derives integration key from record class table name" do
    registry = Folio::Ai::Registry.new

    registry.register_integration(record_class_name: "Folio::Page")

    assert registry.integration(:folio_pages)
  end

  test "uses record translations for integration and field labels" do
    registry = Folio::Ai::Registry.new

    registry.register_integration(record_class_name: "Dummy::Blog::Article",
                                  fields: %i[title])

    integration = registry.integration(:dummy_blog_articles)
    field = registry.field(:dummy_blog_articles, :title)

    assert_equal Dummy::Blog::Article.model_name.human(count: 2), integration.label
    assert_equal Dummy::Blog::Article.human_attribute_name(:title),
                 field.label(record_class: integration.record_class)
  end

  test "uses explicit labels when provided" do
    registry = Folio::Ai::Registry.new

    registry.register_integration(record_class_name: "Folio::Page",
                                  label: "Content editor",
                                  fields: [
                                    Folio::Ai::Field.new(key: :title,
                                                         label: "Headline"),
                                  ])

    integration = registry.integration(:folio_pages)

    assert_equal "Content editor", integration.label
    assert_equal "Headline", registry.field(:folio_pages, :title).label(record_class: integration.record_class)
  end

  test "infers field input type from record class attributes" do
    title_field = Folio::Ai::Field.new(key: :title)
    perex_field = Folio::Ai::Field.new(key: :perex)
    published_field = Folio::Ai::Field.new(key: :published)
    missing_field = Folio::Ai::Field.new(key: :missing_ai_field)

    assert_equal :string, title_field.input_type(record_class: Dummy::Blog::Article)
    assert_equal :text, perex_field.input_type(record_class: Dummy::Blog::Article)
    assert_nil published_field.input_type(record_class: Dummy::Blog::Article)
    assert_nil missing_field.input_type(record_class: Dummy::Blog::Article)
  end

  test "rejects blank record class name" do
    registry = Folio::Ai::Registry.new

    assert_raises(ArgumentError) do
      registry.register_integration(record_class_name: "")
    end
  end

  test "rejects non record class name" do
    registry = Folio::Ai::Registry.new

    assert_raises(ArgumentError) do
      registry.register_integration(record_class_name: "String")
    end
  end

  test "rejects unknown record class name" do
    registry = Folio::Ai::Registry.new

    assert_raises(ArgumentError) do
      registry.register_integration(record_class_name: "Missing::Article")
    end
  end

  test "rejects blank explicit integration key" do
    registry = Folio::Ai::Registry.new

    assert_raises(ArgumentError) do
      registry.register_integration(key: "",
                                    record_class_name: "Folio::Page")
    end
  end

  test "rejects duplicate integrations" do
    registry = Folio::Ai::Registry.new
    registry.register_integration(key: :articles,
                                  record_class_name: "Folio::Page")

    assert_raises(ArgumentError) do
      registry.register_integration(key: "articles",
                                    record_class_name: "Dummy::Blog::Article")
    end
  end

  test "rejects duplicate fields" do
    registry = Folio::Ai::Registry.new

    assert_raises(ArgumentError) do
      registry.register_integration(record_class_name: "Folio::Page",
                                    fields: %i[title title])
    end
  end
end
