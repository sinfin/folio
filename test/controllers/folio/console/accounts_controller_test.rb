# frozen_string_literal: true

require "test_helper"

class Folio::Console::AccountsControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, Folio::Account])
    assert_response :success
    create(:folio_admin_account)
    get url_for([:console, Folio::Account])
    assert_response :success
  end

  test "new" do
    get url_for([:console, Folio::Account, action: :new])
    assert_response :success
  end

  test "edit" do
    model = create(:folio_admin_account)
    get url_for([:edit, :console, model])
    assert_response :success
  end

  test "create" do
    params = build(:folio_admin_account).serializable_hash

    assert_difference("Folio::Account.count", 1) do
      post url_for([:console, Folio::Account]), params: {
        account: params,
      }
    end
  end

  test "update" do
    model = create(:folio_admin_account)
    assert_not_equal("foo@bar.com", model.email)
    put url_for([:console, model]), params: {
      account: {
        email: "foo@bar.com",
      },
    }
    assert_redirected_to url_for([:edit, :console, model])
    assert_equal("foo@bar.com", model.reload.email)
  end

  test "destroy" do
    model = create(:folio_admin_account)
    delete url_for([:console, model])
    assert_redirected_to url_for([:console, Folio::Account])
    assert_not(Folio::Account.exists?(id: model.id))
  end

  test "invite_and_copy" do
    model = create(:folio_admin_account)
    post url_for([:invite_and_copy, :console, model])
    assert_response(422)

    model.update!(invitation_created_at: 1.day.ago)
    post url_for([:invite_and_copy, :console, model])
    assert_response(:success)
  end
end
