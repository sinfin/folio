# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::PagyComponentTest < Folio::Console::ComponentTest
  # The file indexes render pagination above and below the list with the same options; ViewComponent instances are
  # single-use, so a middle component class must give each bar its own instance.
  def test_middle_component_class_renders_in_each_bar
    options = { middle_component: Folio::Console::Files::DisplayToggleComponent }

    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        2.times do
          render_inline(Folio::Console::Ui::PagyComponent.new(pagy: Pagy.new(count: 50, page: 1), options:))

          assert_selector(".f-c-ui-pagy__middle .f-c-files-display-toggle")
        end
      end
    end
  end
end
