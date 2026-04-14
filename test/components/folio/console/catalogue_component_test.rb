# frozen_string_literal: true

require "test_helper"

class Folio::Console::CatalogueComponentTest < Folio::Console::ComponentTest
  def vc_test_controller_class
    Folio::Console::PagesController
  end

  test "renders table with records" do
    klass = Folio::Page
    records = create_list(:folio_page, 1)
    block = proc { edit_link(:title) }

    render_inline(Folio::Console::CatalogueComponent.new(
      klass:,
      records:,
      block:,
    ))

    assert_selector(".f-c-catalogue")
    assert_includes rendered_content, "f-c-catalogue__header-cell--title"
    assert_no_selector(".f-c-index-no-records")
  end

  test "renders no records when empty" do
    klass = Folio::Page
    records = []
    block = proc { edit_link(:title) }

    render_inline(Folio::Console::CatalogueComponent.new(
      klass:,
      records:,
      block:,
    ))

    assert_selector(".f-c-catalogue")
    assert_no_selector(".f-c-catalogue__header-cell")
    assert_selector(".f-c-index-no-records")
  end

  test "adds Stimulus catalogue controller when collection actions present" do
    klass = Folio::Page
    records = create_list(:folio_page, 1)
    block = proc { edit_link(:title) }

    render_inline(Folio::Console::CatalogueComponent.new(
      klass:,
      records:,
      block:,
      collection_actions: [:csv],
    ))

    assert_match(/data-controller="[^"]*\bf-c-catalogue\b/, rendered_content)
    assert_selector(".f-c-catalogue__collection-actions-bar[data-f-c-catalogue-target='collectionBar']")
  end
end
