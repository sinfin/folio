# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::AasmControllerTest < Folio::Console::BaseControllerTest
  test "event" do
    lead = create(:folio_lead)
    assert_equal "submitted", lead.aasm_state

    post event_console_api_aasm_path, params: {
      klass: "Folio::Lead",
      id: lead.id,
      aasm_event: "to_handled",
      cell_options: { small: true }
    }

    assert_response(:success)
    json = JSON.parse(response.body)

    assert json["data"].include?("f-c-state--small")

    post event_console_api_aasm_path, params: {
      klass: "Folio::Lead",
      id: lead.id,
      aasm_event: "to_handled",
    }
    assert_response(422)

    post event_console_api_aasm_path, params: {
      klass: "Foo::Bar",
      id: lead.id,
      aasm_event: "to_handled",
    }
    assert_response(422)

    post event_console_api_aasm_path, params: {
      klass: "Folio::Lead",
      id: 0,
      aasm_event: "to_handled",
    }
    assert_response(422)

    lead.define_singleton_method(:skip_note_validation?) do
      aasm_state == "submitted"
    end

    lead.note = nil
    lead.save!

    post event_console_api_aasm_path, params: {
      klass: "Folio::Lead",
      id: lead.id,
      aasm_event: "to_handled"
    }

    assert_response 422
    json = JSON.parse(response.body)
    assert_equal 422, json["errors"].first["status"]
    assert_equal "Záznam nelze uložit. Před změnou stavu jej opravte.", json["errors"].first["detail"]
    assert json["errors"].first["title"].present?
    assert_equal 1, json["errors"].length
  end

  test "event with reload_form parameter when record is invalid includes validation_box_html in meta" do
    lead = create(:folio_lead)
    lead.define_singleton_method(:skip_note_validation?) do
      aasm_state == "submitted"
    end

    lead.note = nil
    lead.save!

    post event_console_api_aasm_path, params: {
      klass: "Folio::Lead",
      id: lead.id,
      aasm_event: "to_handled",
      reload_form: true
    }

    assert_response 422
    json = JSON.parse(response.body)
    assert_equal 422, json["errors"].first["status"]
    assert json["errors"].first["title"].present?
    assert json["meta"].present?
    assert json["meta"]["validation_box_html"].present?
    assert json["meta"]["validation_box_html"].include?("f-c-ui-validation-box")
  end

  test "event with reload_form parameter when record is valid does not include validation_box_html" do
    lead = create(:folio_lead)
    assert_equal "submitted", lead.aasm_state

    post event_console_api_aasm_path, params: {
      klass: "Folio::Lead",
      id: lead.id,
      aasm_event: "to_handled",
      reload_form: true
    }

    assert_response(:success)
    json = JSON.parse(response.body)
    assert json["data"].present?
    assert json["meta"].nil? || json["meta"]["validation_box_html"].nil?
  end

  test "event without reload_form parameter does not include validation_box_html" do
    lead = create(:folio_lead)
    lead.define_singleton_method(:skip_note_validation?) do
      aasm_state == "submitted"
    end

    lead.note = nil
    lead.save!

    post event_console_api_aasm_path, params: {
      klass: "Folio::Lead",
      id: lead.id,
      aasm_event: "to_handled"
    }

    assert_response 422
    json = JSON.parse(response.body)
    assert_equal 422, json["errors"].first["status"]
    assert json["errors"].first["title"].present?
    assert_nil json["meta"]
  end
end
