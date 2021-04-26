# frozen_string_literal: true

require "test_helper"

class Folio::Omniauth::AuthenticationTest < ActiveSupport::TestCase
  test "find_or_create_user new" do
    assert_equal(0, Folio::User.count)
    auth = create_omniauth_authentication("foo@foo.foo", "foo")
    assert_equal(0, Folio::User.count)

    assert auth.find_or_create_user!

    assert_equal(1, Folio::User.count)
    assert_equal(Folio::User.last, auth.reload.user)
  end

  test "find_or_create_user conflict" do
    assert_equal(0, Folio::User.count)
    user = create(:folio_user, email: "foo@foo.foo")
    auth = create_omniauth_authentication("foo@foo.foo", "foo")
    assert_equal(1, Folio::User.count)

    assert_not auth.find_or_create_user!

    assert_equal(1, Folio::User.count)
    assert_nil(auth.reload.user)
    assert_not_nil(auth.conflict_token)
    assert_equal(user.id, auth.conflict_user_id)
  end
end
