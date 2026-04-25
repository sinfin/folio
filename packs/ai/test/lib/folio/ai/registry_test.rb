# frozen_string_literal: true

require "test_helper"

class Folio::Ai::RegistryTest < ActiveSupport::TestCase
  test "registers integration fields" do
    registry = Folio::Ai::Registry.new

    registry.register_integration(:articles,
                                  fields: [
                                    :title,
                                    { key: :perex, character_limit: 400, auto_attach: true },
                                  ])

    assert registry.field_registered?(:articles, :title)
    assert registry.field_registered?("articles", "perex")
    assert registry.field(:articles, :perex).auto_attach?
    assert_equal 400, registry.field(:articles, :perex).character_limit
  end

  test "rejects duplicate integrations" do
    registry = Folio::Ai::Registry.new
    registry.register_integration(:articles)

    assert_raises(ArgumentError) do
      registry.register_integration("articles")
    end
  end

  test "rejects duplicate fields" do
    registry = Folio::Ai::Registry.new

    assert_raises(ArgumentError) do
      registry.register_integration(:articles, fields: %i[title title])
    end
  end
end
