# frozen_string_literal: true

require "test_helper"

module Folio
  class LeadsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    def setup
      create(:folio_site)
    end

    test "invalid" do
      post leads_path, params: {
        lead: {
          name: "foo",
        }
      }
      assert_response(:success)
      html = Nokogiri::HTML(response.body)
      assert_equal 0, html.css(".folio-lead-form-submitted").size
      assert_equal 1, html.css(".form-group-invalid #lead_email").size
    end

    test "valid" do
      post leads_path, params: {
        lead: {
          email: "foo@bar.baz",
          note: "foo",
        }
      }
      assert_response(:success)
      html = Nokogiri::HTML(response.body)
      assert_equal 1, html.css(".folio-lead-form-submitted").size
    end
  end
end
