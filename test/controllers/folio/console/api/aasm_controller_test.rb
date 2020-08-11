# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Api::AasmControllerTest < Folio::Console::BaseControllerTest
  test 'event' do
    lead = create(:folio_lead)
    assert_equal 'submitted', lead.aasm_state

    post event_console_api_aasm_path, params: {
      klass: 'Folio::Lead',
      id: lead.id,
      aasm_event: 'handle',
      cell_options: { small: true }
    }

    assert_response(:success)
    json = JSON.parse(response.body)

    assert json['data'].include?('f-c-state--small')

    post event_console_api_aasm_path, params: {
      klass: 'Folio::Lead',
      id: lead.id,
      aasm_event: 'handle',
    }
    assert_response(422)

    post event_console_api_aasm_path, params: {
      klass: 'Foo::Bar',
      id: lead.id,
      aasm_event: 'handle',
    }
    assert_response(422)

    post event_console_api_aasm_path, params: {
      klass: 'Folio::Lead',
      id: 0,
      aasm_event: 'handle',
    }
    assert_response(422)
  end
end
