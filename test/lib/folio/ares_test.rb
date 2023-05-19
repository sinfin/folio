# frozen_string_literal: true

require "test_helper"

class Folio::AresTest < ActiveSupport::TestCase
  test "get" do
    subject = Folio::Ares.get(27074358)

    assert_equal "27074358", subject.identification_number
    assert_equal "CZ27074358", subject.vat_identification_number
    assert_equal "Asseco Central Europe, a.s.", subject.company_name
    assert_equal "Praha", subject.city
    assert_equal "Budějovická", subject.address_line_1
    assert_equal "778", subject.address_line_2
    assert_equal "14000", subject.zip
    assert_equal "CZ", subject.country_code
  end
end
