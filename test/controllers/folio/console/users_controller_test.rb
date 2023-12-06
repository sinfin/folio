# frozen_string_literal: true

require "test_helper"

class Folio::Console::UsersControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, Folio::User])
    assert_response :success

    create(:folio_user)

    get url_for([:console, Folio::User])
    assert_response :success
  end

  test "new" do
    get url_for([:console, Folio::User, action: :new])
    assert_response :success
  end

  test "edit" do
    model = create(:folio_user)
    get url_for([:edit, :console, model])
    assert_response :success
  end

  test "create" do
    params = build(:folio_user, email: "foo@bar.com").serializable_hash

    assert_difference("Folio::User.count", 1) do
      post url_for([:console, Folio::User]), params: {
        user: params,
      }
    end

    assert_equal @admin, Folio::User.find_by_email("foo@bar.com").invited_by
  end

  test "update" do
    model = create(:folio_user)
    assert_not_equal("foo@bar.com", model.email)
    put url_for([:console, model]), params: {
      user: {
        email: "foo@bar.com",
        use_secondary_address: "1",
        secondary_address_attributes: {
          name: "Foo Von Bar",
          company_name: "",
          address_line_1: "Example steet",
          address_line_2: "75",
          city: "Somewhere",
          zip: "12345",
          country_code: "CZ"
        }
      },
    }
    assert_redirected_to url_for([:edit, :console, model])

    if Rails.application.config.folio_users_confirmable
      assert_equal("foo@bar.com", model.reload.unconfirmed_email)
    else
      assert_equal("foo@bar.com", model.reload.email)
    end

    assert model.use_secondary_address
    assert_equal "Somewhere", model.secondary_address.city
  end

  test "destroy" do
    model = create(:folio_user)
    delete url_for([:console, model])
    assert_redirected_to url_for([:console, Folio::User])
    assert_not(Folio::User.exists?(id: model.id))
  end

  test "collection_destroy" do
    models = create_list(:folio_user, 5)

    assert_difference("Folio::User.count", -2) do
      delete url_for([:collection_destroy, :console, Folio::User]), params: {
        ids: "#{models[0].id},#{models[1].id}"
      }
      assert_redirected_to url_for([:console, Folio::User])
    end
  end

  test "collection_csv" do
    models = create_list(:folio_user, 5)

    get url_for([:collection_csv, :console, Folio::User]), params: {
      ids: "#{models[0].id},#{models[1].id}"
    }
    assert_response(:success)
  end
end
