# frozen_string_literal: true

require "test_helper"

class Folio::HasSanitizedFieldsTest < ActiveSupport::TestCase
  test "strips tags" do
    assert Folio::Lead.fields_to_sanitize.include?(:email)

    lead = Folio::Lead.new(email: "<p>email@email.email</p>",
                           note: "note with <script>alert('alert')</script>")

    assert lead.save

    assert_equal "email@email.email", lead.email
    assert_equal "note with alert('alert')", lead.note
  end
end
