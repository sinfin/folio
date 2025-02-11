# frozen_string_literal: true

require "test_helper"

class Folio::Console::Audited::DropdownComponentTest < Folio::Console::ComponentTest
  class AuditedPage < Folio::Page
    include Folio::Audited
    audited
  end

  def test_without_audits
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages" do
        Audited.stub(:auditing_enabled, true) do
          site = get_any_site
          page = AuditedPage.create!(title: "v1", site:)

          render_inline(Folio::Console::Audited::DropdownComponent.new(record: page,
                                                                       audits: page.audits))

          assert_no_selector(".f-c-audited-dropdown")
        end
      end
    end
  end

  def test_with_audits
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages" do
        Audited.stub(:auditing_enabled, true) do
          site = get_any_site
          page = AuditedPage.create!(title: "v1", site:)

          page.update!(title: "foo")
          page.update!(title: "bar")

          render_inline(Folio::Console::Audited::DropdownComponent.new(record: page,
                                                                       audits: page.audits))

          assert_selector(".f-c-audited-dropdown")
        end
      end
    end
  end
end
