# frozen_string_literal: true

class Folio::Ai::PromptComposer
  Result = Struct.new(:prompt, :default_prompt, :user_instruction, :context, keyword_init: true)

  def initialize(default_prompt:, user_instruction: nil, context: {})
    @default_prompt = default_prompt.to_s.strip
    @user_instruction = user_instruction.to_s.strip
    @context = context || {}
  end

  def call
    raise ArgumentError, "Default AI prompt is blank" if default_prompt.blank?

    Result.new(prompt: sections.join("\n\n"),
               default_prompt:,
               user_instruction:,
               context:)
  end

  private
    attr_reader :default_prompt,
                :user_instruction,
                :context

    def sections
      [
        section("Default instructions", default_prompt),
        optional_section("User instructions", user_instruction),
        optional_section("Context", formatted_context),
      ].compact
    end

    def section(title, body)
      "#{title}:\n#{body}"
    end

    def optional_section(title, body)
      return if body.blank?

      section(title, body)
    end

    def formatted_context
      return context.to_s if context.is_a?(String)
      return if context.blank?

      JSON.pretty_generate(context)
    end
end
