# frozen_string_literal: true

require "test_helper"

class Folio::InvalidUsersCheckJobTest < ActiveJob::TestCase
  test "find invalid users and reports them" do
    u_valid = create(:folio_user)
    u_invalid_mail = create(:folio_user)
    u_invalid_mail.update_column(:email, "invalid_mail")
    u_invalid_names = create(:folio_user, invitation_accepted_at: Time.current)
    u_invalid_names.update_column(:first_name, "")
    u_invalid_names.update_column(:last_name, "")


    assert u_valid.reload.valid?
    assert_not u_invalid_mail.reload.valid?
    assert_not u_invalid_names.reload.valid?

    ex = assert_raises Folio::InvalidUsersCheckJob::InvalidUsersError do
      Folio::InvalidUsersCheckJob.perform_now
    end

    assert ex.message.include?("[##{u_invalid_mail.id}] email: není platná hodnota"), ex.message
    assert ex.message.include?("[##{u_invalid_names.id}] first_name: je povinná položka; last_name: je povinná položka"), ex.message
    assert_not ex.message.include?("[##{u_valid.id}]"), ex.message
  end
end
