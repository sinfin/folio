# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::Index::Header::QueryFormComponentTest < Folio::Console::ComponentTest
  def test_render
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages" do
        klass = Folio::Page

        render_inline(Folio::Console::Ui::Index::Header::QueryFormComponent.new(klass:,
                                                                                query_url: "/foo"))

        assert_selector(".f-c-ui-index-header-query-form")
      end
    end
  end
end
