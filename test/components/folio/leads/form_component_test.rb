# frozen_string_literal: true

require "test_helper"

class Folio::Leads::FormComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Folio::Leads::FormComponent.new)

    assert_selector(".f-leads-form")
  end

  def test_requires_session_for_component
    with_controller_class(ApplicationController) do
      # Mock the controller to track session requirements
      vc_test_controller.define_singleton_method(:require_session_for_component!) do |reason|
        @component_session_requirements ||= []
        @component_session_requirements << reason
      end

      render_inline(Folio::Leads::FormComponent.new)

      requirements = vc_test_controller.instance_variable_get(:@component_session_requirements)
      assert_includes requirements, "lead_form_csrf_and_flash"
    end
  end

  def test_renders_with_lead_instance
    lead = Folio::Lead.new(email: "test@example.com")
    render_inline(Folio::Leads::FormComponent.new(lead: lead))

    assert_selector(".f-leads-form")
    assert_selector("input[value='test@example.com']")
  end
end
