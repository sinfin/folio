# frozen_string_literal: true

require "test_helper"

class Folio::Ai::RequestGuardTest < ActiveSupport::TestCase
  test "allows prompt under configured cost limit" do
    with_config(folio_ai_max_prompt_chars: 10) do
      assert_nothing_raised do
        guard(prompt: "short").check!
      end
    end
  end

  test "rejects prompt over configured cost limit" do
    with_config(folio_ai_max_prompt_chars: 3) do
      assert_raises(Folio::Ai::CostLimitExceededError) do
        guard(prompt: "too long").check!
      end
    end
  end

  private
    def guard(prompt:)
      Folio::Ai::RequestGuard.new(site: build(:folio_site),
                                  user: build(:folio_user),
                                  integration_key: :articles,
                                  field_key: :title,
                                  prompt:)
    end
end
