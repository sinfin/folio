# frozen_string_literal: true

FactoryBot.define do
  factory :folio_ai_user_instruction, class: "Folio::Ai::UserInstruction" do
    user { create(:folio_user) }
    site { user.auth_site }
    integration_key { "articles" }
    field_key { "title" }
    instruction { "Use a concise tone." }
  end
end
