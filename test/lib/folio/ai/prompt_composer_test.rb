# frozen_string_literal: true

require "test_helper"

class Folio::Ai::PromptComposerTest < ActiveSupport::TestCase
  test "composes default prompt, user instruction and context" do
    result = Folio::Ai::PromptComposer.new(default_prompt: "Write a headline.",
                                           user_instruction: "Make it shorter.",
                                           context: { title: "Original" }).call

    assert_includes result.prompt, "Default instructions:\nWrite a headline."
    assert_includes result.prompt, "User instructions:\nMake it shorter."
    assert_includes result.prompt, '"title": "Original"'
  end

  test "omits blank optional sections" do
    result = Folio::Ai::PromptComposer.new(default_prompt: "Write.",
                                           user_instruction: "",
                                           context: {}).call

    assert_includes result.prompt, "Default instructions:\nWrite."
    assert_not_includes result.prompt, "User instructions"
    assert_not_includes result.prompt, "Context"
  end

  test "raises for blank default prompt" do
    assert_raises(ArgumentError) do
      Folio::Ai::PromptComposer.new(default_prompt: " ").call
    end
  end
end
