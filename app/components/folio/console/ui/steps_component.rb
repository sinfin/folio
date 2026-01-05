# frozen_string_literal: true

class Folio::Console::Ui::StepsComponent < Folio::Console::ApplicationComponent
  def initialize(steps:, current_index: 0)
    @steps = steps
    @current_index = current_index
  end

  private
    def steps_with_marks
      @steps_with_marks ||= @steps.each_with_index.map do |step, index|
        state = if index < @current_index
          :done
        elsif index == @current_index
          :current
        else
          :upcoming
        end

        tag = {
          tag: :span,
          class: "f-c-ui-steps__step f-c-ui-steps__step--state-#{state}"
        }

        if step[:href] && state == :done
          tag[:tag] = :a
          tag[:href] = step[:href]
          tag[:target] = step[:target]
        end

        {
          tag:,
          state:,
          number: index + 1,
          label: step[:label],
        }
      end
    end
end
