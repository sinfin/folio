# frozen_string_literal: true

require "test_helper"

class Folio::Api::AresControllerTest < ActionDispatch::IntegrationTest
  include Folio::Engine.routes.url_helpers

  def setup
    create_and_host_site
  end

  test "valid" do
    VCR.use_cassette("folio/api/ares/valid") do
      post subject_folio_api_ares_path, params: {
        identification_number: "27074358",
      }

      assert_response(:ok)
      hash = response.parsed_body["data"]

      assert_equal "27074358", hash["identification_number"]
      assert_equal "CZ27074358", hash["vat_identification_number"]
      assert_equal "Asseco Central Europe, a.s.", hash["company_name"]
      assert_equal "Praha", hash["city"]
      assert_equal "Budějovická", hash["address_line_1"]
      assert_equal "778", hash["address_line_2"]
      assert_equal "14000", hash["zip"]
      assert_equal "CZ", hash["country_code"]
    end
  end

  test "invalid" do
    VCR.use_cassette("folio/api/ares/invalid") do
      post subject_folio_api_ares_path, params: {
        identification_number: "x27074358x",
      }

      assert_response(422)
      assert_equal("Folio::Ares::InvalidIdentificationNumberError",
                   response.parsed_body["errors"].first["title"])
    end
  end
end
