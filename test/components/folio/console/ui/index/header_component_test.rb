# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::Index::HeaderComponentTest < Folio::Console::ComponentTest
  def test_render
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages" do
        klass = Folio::Page

        render_inline(Folio::Console::Ui::Index::HeaderComponent.new(klass:))

        assert_selector(".f-c-ui-index-header")
      end
    end
  end
end
