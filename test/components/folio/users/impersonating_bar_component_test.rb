# frozen_string_literal: true

require "test_helper"

class Folio::Users::ImpersonatingBarComponentTest < Folio::ComponentTest
  def test_inactive
    render_inline(Folio::Users::ImpersonatingBarComponent.new)
    assert_no_selector(".f-users-impersonating-bar")
  end

  def test_active
    user = create(:folio_user)
    true_user = create(:folio_user)

    render_inline(Folio::Users::ImpersonatingBarComponent.new(current_user_for_test: user,
                                                              true_user_for_test: true_user))
    assert_selector(".f-users-impersonating-bar")
  end
end
