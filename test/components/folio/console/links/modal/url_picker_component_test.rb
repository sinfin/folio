# frozen_string_literal: true

require "test_helper"

class Folio::Console::Links::Modal::UrlPickerComponentTest < Folio::Console::ComponentTest
  def test_render
    site = get_any_site

    Folio::Current.site = site
    Folio::Current.reset_ability!

    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console" do
        url_json = { href: "/foo" }

        render_inline(Folio::Console::Links::Modal::UrlPickerComponent.new(url_json:))

        assert_selector(".f-c-links-modal-url-picker")
      end
    end
  end
end
