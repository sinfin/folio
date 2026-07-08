# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")
require Folio::Engine.root.join("packs/ai/app/models/concerns/folio/ai/site_concern")
require Folio::Engine.root.join("packs/ai/app/models/concerns/folio/ai/user_concern")
require Folio::Engine.root.join("packs/ai/app/models/folio/ai/user_instruction")

class Folio::Ai::UserInstructionTest < ActiveSupport::TestCase
  setup do
    Folio::Site.include(Folio::Ai::SiteConcern) unless Folio::Site < Folio::Ai::SiteConcern
    Folio::User.include(Folio::Ai::UserConcern) unless Folio::User < Folio::Ai::UserConcern
  end

  test "stores one instruction per user site record and field" do
    site = create(Rails.application.config.folio_site_default_test_factory)
    user = create(:folio_user)

    instruction = Folio::Ai::UserInstruction.upsert_instruction!(user:,
                                                                 site:,
                                                                 record_key: " folio_pages ",
                                                                 field_key: " title ",
                                                                 instruction: "Use shorter copy.")

    assert_equal "folio_pages", instruction.integration_key
    assert_equal "title", instruction.field_key
    assert_equal "Use shorter copy.", instruction.instruction

    updated = Folio::Ai::UserInstruction.upsert_instruction!(user:,
                                                             site:,
                                                             record_key: "folio_pages",
                                                             field_key: "title",
                                                             instruction: "Try another tone.")

    assert_equal instruction.id, updated.id
    assert_equal "Try another tone.", updated.instruction
  end
end
