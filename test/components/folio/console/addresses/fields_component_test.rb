# frozen_string_literal: true

require "test_helper"

class Folio::Console::Addresses::FieldsComponentTest < Folio::Console::ComponentTest
  def test_render
    with_controller_class(Folio::Console::UsersController) do
      user = create(:folio_user)

      vc_test_controller.view_context.simple_form_for(user, url: "/") do |f|
        render_inline(Folio::Console::Addresses::FieldsComponent.new(model: f))
      end

      assert_selector(".f-c-addresses-fields")
    end
  end
end
