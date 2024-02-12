# frozen_string_literal: true

require "test_helper"

class Dummy::Searches::AutocompleteComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Dummy::Searches::AutocompleteComponent.new(model:))

    assert_selector(".d-searches-autocomplete")
  end
end
