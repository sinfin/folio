# frozen_string_literal: true

require "test_helper"

class Folio::Leads::FormComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Folio::Leads::FormComponent.new)

    assert_selector(".f-leads-form")
  end

  def test_renders_with_lead_instance
    lead = Folio::Lead.new(email: "test@example.com")
    render_inline(Folio::Leads::FormComponent.new(lead: lead))

    assert_selector(".f-leads-form")
    assert_selector("input[value='test@example.com']")
  end
end
