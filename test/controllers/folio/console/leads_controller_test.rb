# frozen_string_literal: true

require "test_helper"

class Folio::Console::LeadsControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, Folio::Lead])
    assert_response :success
    create(:folio_lead)
    get url_for([:console, Folio::Lead])
    assert_response :success
  end

  test "index.csv" do
    get url_for([:console, Folio::Lead, format: :csv])
    assert_response :success
    create(:folio_lead)
    get url_for([:console, Folio::Lead, format: :csv])
    assert_response :success
  end

  test "index scoped by ability and site" do
    other_site = create(:folio_site, type: "Folio::Site")
    our_site_lead1 = create(:folio_lead, site: @site, email: "our1@lead.com")
    our_site_lead2 = create(:folio_lead, site: @site, email: "manager_cant@see.me")
    our_site_lead3 = create(:folio_lead, site: @site, email: "manager_can_read_but_not_update@see.me")
    other_site_lead = create(:folio_lead, site: other_site, email: "other@lead.com")

    I18n.with_locale(:cs) do
      get url_for([:console, Folio::Lead])
    end

    assert_response :success
    assert_select ".f-c-pagination__info", text: "Zobrazuji 3 záznamy"
    assert_select ".f-c-catalogue__row", count: 3
    assert_select ".f-c-catalogue__row .f-c-catalogue__cell-value", text: our_site_lead1.email, count: 1
    assert_select ".f-c-catalogue__row .f-c-catalogue__cell-value", text: our_site_lead2.email, count: 1
    assert_select ".f-c-catalogue__row .f-c-catalogue__cell-value", text: our_site_lead3.email, count: 1
    assert_select ".f-c-catalogue__row .f-c-catalogue__cell-value", text: other_site_lead.email, count: 0

    sign_out(@superadmin)
    manager = create(:folio_site_user_link, site: @site, roles: [:manager]).user
    sign_in manager

    I18n.with_locale(:cs) do
      get url_for([:console, Folio::Lead])
    end

    assert_response :success
    # manager can not see lead with email "manager_cant@see.me" (see dummy ability override)
    assert_select ".f-c-pagination__info", text: "Zobrazuji 2 záznamy"
    assert_select ".f-c-catalogue__row", count: 2
    assert_select ".f-c-catalogue__row .f-c-catalogue__cell-value", text: our_site_lead1.email, count: 1
    assert_select ".f-c-catalogue__row .f-c-catalogue__cell-value", text: our_site_lead2.email, count: 0
    assert_select ".f-c-catalogue__row .f-c-catalogue__cell-value", text: our_site_lead3.email, count: 1
    assert_select ".f-c-catalogue__row .f-c-catalogue__cell-value", text: other_site_lead.email, count: 0

    sign_out(manager)
  end

  def teardown
    super
 end


  test "edit" do
    model = create(:folio_lead)
    get url_for([:edit, :console, model])
    assert_response :success
  end

  test "update" do
    model = create(:folio_lead)
    assert_not_equal("email@email.email", model.email)
    put url_for([:console, model]), params: {
      lead: {
        email: "email@email.email",
      },
    }
    assert_redirected_to url_for([:edit, :console, model])
    assert_equal("email@email.email", model.reload.email)
  end

  test "destroy" do
    model = create(:folio_lead)
    delete url_for([:console, model])
    assert_redirected_to url_for([:console, Folio::Lead])
    assert_not(Folio::Lead.exists?(id: model.id))
  end

  test "event" do
    model = create(:folio_lead)
    assert_not(model.handled?)
    post url_for([:event, :console, model]), params: { aasm_event: "to_handled" }
    assert(model.reload.handled?)
  end
end
