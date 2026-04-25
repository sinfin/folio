# frozen_string_literal: true

require "test_helper"

class Folio::Ai::UserInstructionTest < ActiveSupport::TestCase
  test "normalizes keys and stores instruction per user site and field" do
    user = create(:folio_user)

    record = Folio::Ai::UserInstruction.upsert_instruction!(user:,
                                                            site: user.auth_site,
                                                            integration_key: " articles ",
                                                            field_key: :title,
                                                            instruction: "Prefer neutral tone.")

    assert_equal "articles", record.integration_key
    assert_equal "title", record.field_key
    assert_equal "Prefer neutral tone.", record.instruction
  end

  test "upsert updates existing record" do
    user = create(:folio_user)
    site = user.auth_site

    Folio::Ai::UserInstruction.upsert_instruction!(user:,
                                                   site:,
                                                   integration_key: :articles,
                                                   field_key: :title,
                                                   instruction: "First")
    record = Folio::Ai::UserInstruction.upsert_instruction!(user:,
                                                            site:,
                                                            integration_key: :articles,
                                                            field_key: :title,
                                                            instruction: "Second")

    assert_equal "Second", record.instruction
    assert_equal 1, Folio::Ai::UserInstruction.where(user:, site:).count
  end
end
