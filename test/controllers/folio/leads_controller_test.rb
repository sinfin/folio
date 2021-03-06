# frozen_string_literal: true

require "test_helper"

class Folio::LeadsControllerTest < ActionDispatch::IntegrationTest
  include Folio::Engine.routes.url_helpers

  def setup
    create(:folio_site)
  end

  test "invalid" do
    post url_for(Folio::Lead), params: {
      lead: {
        name: "foo",
      }
    }
    assert_response(:success)
    html = Nokogiri::HTML(response.body)
    assert_equal 0, html.css(".f-leads-form--submitted").size
    assert_equal 1, html.css(".form-group-invalid #lead_email").size
  end

  test "valid" do
    post url_for(Folio::Lead), params: {
      lead: {
        email: "foo@bar.baz",
        note: "foo",
      }
    }
    assert_response(:success)
    html = Nokogiri::HTML(response.body)
    assert_equal 1, html.css(".f-leads-form--submitted").size
  end
end
