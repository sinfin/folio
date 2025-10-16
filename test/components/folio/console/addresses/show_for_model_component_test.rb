# frozen_string_literal: true

require "test_helper"

class Folio::Console::Addresses::ShowForModelComponentTest < Folio::Console::ComponentTest
  test "show" do
    user = create(:folio_user)
    render_inline(Folio::Console::Addresses::ShowForModelComponent.new(model: user))
    assert_selector(".f-c-addresses-show-for-model")

    render_inline(Folio::Console::Addresses::ShowForModelComponent.new(model:))

    assert_selector(".f-c-addresses-show-for-model")
  end
end
