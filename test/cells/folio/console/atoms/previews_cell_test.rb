# frozen_string_literal: true

require "test_helper"

class Folio::Console::Atoms::PreviewsCellTest < Folio::Console::CellTest
  class NonInsertableAtom < Folio::Atom::Base
    def self.insertable_in_console?(site:)
      false
    end
  end

  test "show" do
    create_and_host_site

    html = cell("folio/console/atoms/previews", nil, klass: Folio::Page).(:show)
    assert_not html.has_css?(".f-c-atoms-previews")

    html = cell("folio/console/atoms/previews", { cs: [] }, klass: Folio::Page).(:show)
    assert html.has_css?(".f-c-atoms-previews")
    assert_not html.has_css?("[data-type='#{NonInsertableAtom.name}']")
  end
end
