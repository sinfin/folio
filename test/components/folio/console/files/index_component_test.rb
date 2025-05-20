# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::IndexComponentTest < Folio::Console::ComponentTest
  def test_render
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages" do
        file_klass = Folio::File::Image
        files = [create(:folio_file_image)]
        modal = false

        render_inline(Folio::Console::Files::IndexComponent.new(file_klass:, files:, modal:))

        assert_selector(".f-c-files-index")
      end
    end
  end

  def test_render_modal
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages" do
        file_klass = Folio::File::Image
        files = [create(:folio_file_image)]
        modal = true

        render_inline(Folio::Console::Files::IndexComponent.new(file_klass:, files:, modal:))

        assert_selector(".f-c-files-index")
      end
    end
  end
end
