# frozen_string_literal: true

require "test_helper"

class Folio::Leads::FormComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Folio::Leads::FormComponent.new)

    assert_selector(".f-leads-form")
  end
end
