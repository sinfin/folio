# frozen_string_literal: true

require "test_helper"

class Folio::EmailTemplateTest < ActiveSupport::TestCase
  test "validate subjects" do
    et = build(:folio_email_template,
               subject_cs: nil,
               subject_en: "subject_en")
    assert_not et.valid?
    assert_equal [:subject_cs], et.errors.keys
    assert_equal [{ error: :blank }], et.errors.details[:subject_cs]
  end

  test "validate bodies" do
    et = build(:folio_email_template,
               body_cs: nil,
               body_en: "body_en")
    assert_not et.valid?
    assert_equal [:body_cs], et.errors.keys
    assert_equal [{ error: :blank }], et.errors.details[:body_cs]

    et = build(:folio_email_template,
               body_cs: "foo",
               body_en: "foo {KEYWORD} bar",
               required_keywords: %w[KEYWORD],
               optional_keywords: %w[])
    assert_not et.valid?
    assert_equal [:body_cs], et.errors.keys
    assert_equal [{ error: :missing_keyword }], et.errors.details[:body_cs]
  end
end
