# frozen_string_literal: true

require 'test_helper'

class Folio::Console::LeadsControllerTest < Folio::Console::BaseControllerTest
  test 'index' do
    get console_leads_path
    assert_response :success
  end

  test 'show' do
    get console_lead_path(create(:folio_lead))
    assert_response :success
  end

  test 'destroy' do
    model = create(:folio_lead)
    delete console_lead_path(model.id)
    assert_redirected_to console_leads_path
    assert_not(Folio::Lead.exists?(id: model.id))
  end

  test 'handle / unhandle' do
    model = create(:folio_lead)
    assert_not(model.handled?)
    patch handle_console_lead_path(model.id)
    assert_redirected_to console_leads_path
    assert(model.reload.handled?)

    patch unhandle_console_lead_path(model.id)
    assert_redirected_to console_leads_path
    assert_not(model.reload.handled?)
  end

  test 'mass_handle' do
    models = create_list(:folio_lead, 3)
    model = create(:folio_lead)

    assert(models.none? { |m| m.handled? })
    post mass_handle_console_leads_path, params: {
      leads: models.map(&:id),
    }
    assert_redirected_to console_leads_path
    assert(models.all? { |m| m.reload.handled? })
    assert_not(model.reload.handled?)
  end
end
