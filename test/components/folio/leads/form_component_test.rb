# frozen_string_literal: true

require "test_helper"

class Folio::Leads::FormComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Folio::Leads::FormComponent.new)

    assert_selector(".f-leads-form")
  end

  def test_requires_session_for_component
    component = Folio::Leads::FormComponent.new

    # Test polymorphic API
    assert component.requires_session?
    assert_equal "lead_form_csrf_and_flash", component.session_requirement_reason

    # Test session requirement hash structure
    requirement = component.session_requirement
    assert_equal "lead_form_csrf_and_flash", requirement[:reason]
    assert requirement[:component].include?("FormComponent")
    assert_kind_of Time, requirement[:timestamp]
  end

  def test_renders_with_lead_instance
    lead = Folio::Lead.new(email: "test@example.com")
    render_inline(Folio::Leads::FormComponent.new(lead: lead))

    assert_selector(".f-leads-form")
    assert_selector("input[value='test@example.com']")
  end
end
