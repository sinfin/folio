# frozen_string_literal: true

require "test_helper"

class Folio::Tiptap::ModelLocalesTest < ActiveSupport::TestCase
  test "has_folio_tiptap_content with locales registers locale-suffixed fields" do
    model_class = Class.new(Folio::ApplicationRecord) do
      self.table_name = "folio_pages"
      include Folio::Tiptap::Model
    end

    model_class.has_folio_tiptap_content(locales: %i[cs en])

    assert_equal %w[tiptap_content_cs tiptap_content_en], model_class.folio_tiptap_fields.sort
  end

  test "has_folio_tiptap_content with locales sets folio_tiptap_locales correctly" do
    model_class = Class.new(Folio::ApplicationRecord) do
      self.table_name = "folio_pages"
      include Folio::Tiptap::Model
    end

    model_class.has_folio_tiptap_content(locales: %i[cs en])

    assert_equal({ "tiptap_content" => [:cs, :en] }, model_class.folio_tiptap_locales)
  end

  test "has_folio_tiptap_content without locales maintains existing behavior" do
    model_class = Class.new(Folio::ApplicationRecord) do
      self.table_name = "folio_pages"
      include Folio::Tiptap::Model
    end

    model_class.has_folio_tiptap_content

    assert_equal %w[tiptap_content], model_class.folio_tiptap_fields
    assert_equal({}, model_class.folio_tiptap_locales)
  end

  test "has_folio_tiptap_content is idempotent when called with same configuration" do
    model_class = Class.new(Folio::ApplicationRecord) do
      self.table_name = "folio_pages"
      include Folio::Tiptap::Model
    end

    model_class.has_folio_tiptap_content(locales: %i[cs en])
    initial_fields = model_class.folio_tiptap_fields.dup
    initial_locales = model_class.folio_tiptap_locales.dup

    model_class.has_folio_tiptap_content(locales: %i[cs en])

    assert_equal initial_fields.sort, model_class.folio_tiptap_fields.sort
    assert_equal initial_locales, model_class.folio_tiptap_locales
  end

  test "has_folio_tiptap_content updates configuration when called with different locales" do
    model_class = Class.new(Folio::ApplicationRecord) do
      self.table_name = "folio_pages"
      include Folio::Tiptap::Model
    end

    model_class.has_folio_tiptap_content(locales: %i[cs en])
    assert_equal %w[tiptap_content_cs tiptap_content_en], model_class.folio_tiptap_fields.sort
    assert_equal({ "tiptap_content" => [:cs, :en] }, model_class.folio_tiptap_locales)

    model_class.has_folio_tiptap_content(locales: %i[de fr])
    assert_equal %w[tiptap_content_de tiptap_content_fr], model_class.folio_tiptap_fields.sort
    assert_equal({ "tiptap_content" => [:de, :fr] }, model_class.folio_tiptap_locales)
  end

  test "has_folio_tiptap_content switches from localized to non-localized" do
    model_class = Class.new(Folio::ApplicationRecord) do
      self.table_name = "folio_pages"
      include Folio::Tiptap::Model
    end

    model_class.has_folio_tiptap_content(locales: %i[cs en])
    assert_equal %w[tiptap_content_cs tiptap_content_en], model_class.folio_tiptap_fields.sort
    assert_equal({ "tiptap_content" => [:cs, :en] }, model_class.folio_tiptap_locales)

    model_class.has_folio_tiptap_content
    assert_equal %w[tiptap_content], model_class.folio_tiptap_fields
    assert_equal({}, model_class.folio_tiptap_locales)
  end

  test "has_folio_tiptap_content switches from non-localized to localized" do
    model_class = Class.new(Folio::ApplicationRecord) do
      self.table_name = "folio_pages"
      include Folio::Tiptap::Model
    end

    model_class.has_folio_tiptap_content
    assert_equal %w[tiptap_content], model_class.folio_tiptap_fields
    assert_equal({}, model_class.folio_tiptap_locales)

    model_class.has_folio_tiptap_content(locales: %i[cs en])
    assert_equal %w[tiptap_content_cs tiptap_content_en], model_class.folio_tiptap_fields.sort
    assert_equal({ "tiptap_content" => [:cs, :en] }, model_class.folio_tiptap_locales)
  end
end
