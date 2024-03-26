# frozen_string_literal: true

require "test_helper"

class Folio::LeadsControllerTest < ActionDispatch::IntegrationTest
  include Folio::Engine.routes.url_helpers

  def setup
    create_and_host_site
  end

  test "invalid html" do
    assert_difference("Folio::Lead.count", 0) do
      post url_for(Folio::Lead), params: {
        lead: {
          name: "foo",
        }
      }

      assert_redirected_to main_app.root_path
    end
  end

  test "valid html" do
    assert_difference("Folio::Lead.count", 1) do
      post url_for(Folio::Lead), params: {
        lead: {
          email: "foo@bar.baz",
          note: "foo",
        }
      }

      assert_redirected_to main_app.root_path
    end
  end

  test "invalid json" do
    post url_for([Folio::Lead, format: :json]), params: {
      lead: {
        name: "foo",
      }
    }
    assert_response(:success)
    assert response.parsed_body["data"]
  end

  test "valid json" do
    post url_for([Folio::Lead, format: :json]), params: {
      lead: {
        email: "foo@bar.baz",
        note: "foo",
      }
    }
    assert_response(:success)
    assert response.parsed_body["data"]
  end
end
