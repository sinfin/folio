# frozen_string_literal: true

require "test_helper"

class Folio::Console::Links::Modal::ListComponentTest < Folio::Console::ComponentTest
  def test_render
    site = get_any_site

    Folio::Current.site = site
    Folio::Current.reset_ability!

    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console" do
        render_inline(Folio::Console::Links::Modal::ListComponent.new)
        assert_selector(".f-c-links-modal-list")
      end
    end
  end
end
