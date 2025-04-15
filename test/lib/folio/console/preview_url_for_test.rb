# frozen_string_literal: true

require "test_helper"

class Folio::Console::PreviewUrlForTest < Folio::Console::ComponentTest
  class TestComponent < Folio::Console::ApplicationComponent
    slim_template <<~SLIM
      = preview_url_for(@record)
    SLIM

    def initialize(record:)
      @record = record
    end
  end

  def test_page
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages" do
        page = create(:folio_page)
        render_inline(TestComponent.new(record: page))
        assert_equal "http://test.host/#{page.slug}", rendered_content
      end
    end
  end

  def test_unpublished_page
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages" do
        page = create(:folio_page, published: false)
        render_inline(TestComponent.new(record: page))
        assert_equal "http://test.host/#{page.slug}?preview=#{page.preview_token}", rendered_content
      end
    end
  end

  def test_page_with_wrong_locale
    Rails.application.config.stub(:folio_pages_locales, true) do
      with_controller_class(Folio::Console::PagesController) do
        with_request_url "/console/pages" do
          page = create(:folio_page)
          page.update_column(:locale, "xyz")
          render_inline(TestComponent.new(record: page))
          assert_equal "", rendered_content
        end
      end
    end
  end

  def test_non_public_page
    Folio::Page.stub(:public?, false) do
      with_controller_class(Folio::Console::PagesController) do
        with_request_url "/console/pages" do
          page = create(:folio_page)
          render_inline(TestComponent.new(record: page))
          assert_equal "", rendered_content
        end
      end
    end
  end

  def test_page_with_public_rails_path
    Folio::Page.stub(:public_rails_path, :root_path) do
      with_controller_class(Folio::Console::PagesController) do
        with_request_url "/console/pages" do
          page = create(:folio_page)
          render_inline(TestComponent.new(record: page))
          assert_equal "http://test.host/", rendered_content
        end
      end
    end
  end

  def test_page_with_procs
    procs = {
      "Folio::Page" => proc { |record, controller| "/record-#{record.id}/controller-#{controller.class}" }
    }

    Rails.application.config.stub(:folio_console_preview_url_for_procs, procs) do
      with_controller_class(Folio::Console::PagesController) do
        with_request_url "/console/pages" do
          page = create(:folio_page)
          render_inline(TestComponent.new(record: page))
          assert_equal "/record-#{page.id}/controller-Folio::Console::PagesController", rendered_content
        end
      end
    end
  end
end
