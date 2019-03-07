# frozen_string_literal: true

require 'test_helper'

class Folio::Console::LeadsControllerTest < Folio::Console::BaseControllerTest
  test 'index' do
    get url_for([:console, Folio::Lead])
    assert_response :success
    create(:folio_lead)
    get url_for([:console, Folio::Lead])
    assert_response :success
  end

  test 'edit' do
    model = create(:folio_lead)
    get url_for([:edit, :console, model])
    assert_response :success
  end

  test 'update' do
    model = create(:folio_lead)
    assert_not_equal('email@email.email', model.email)
    put url_for([:console, model]), params: {
      lead: {
        email: 'email@email.email',
      },
    }
    assert_redirected_to url_for([:edit, :console, model])
    assert_equal('email@email.email', model.reload.email)
  end

  test 'destroy' do
    model = create(:folio_lead)
    delete url_for([:console, model])
    assert_redirected_to url_for([:console, Folio::Lead])
    assert_not(Folio::Lead.exists?(id: model.id))
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
