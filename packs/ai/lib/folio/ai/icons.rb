# frozen_string_literal: true

module Folio::Ai::Icons
  SPARKLES_PATH = "M19 1l1.25 2.75L23 5l-2.75 1.25L19 9l-1.25-2.75L15 5l2.75-1.25L19 1z" \
                  "M9 4l2.5 5.5L17 12l-5.5 2.5L9 20l-2.5-5.5L1 12l5.5-2.5L9 4z" \
                  "M19 15l1.25 2.75L23 19l-2.75 1.25L19 23l-1.25-2.75L15 19l2.75-1.25L19 15z"
  UNDO_PATH = "M20 13.5a6.5 6.5 0 01-6.5 6.5H6v-2h7.5c2.5 0 4.5-2 4.5-4.5S16 9 13.5 9H7.83l3.08 3.09L9.5 13.5 4 8l5.5-5.5 1.42 1.41L7.83 7h5.67a6.5 6.5 0 016.5 6.5z"

  class << self
    def sparkles(template, class_name: nil)
      template.tag.span(class: class_names("f-c-ai-text-suggestions__spark", class_name), aria: { hidden: true }) do
        template.tag.svg(class: "f-c-ai-text-suggestions__spark-svg",
                         fill: "none",
                         viewBox: "0 0 24 24",
                         xmlns: "http://www.w3.org/2000/svg") do
          template.tag.path(d: SPARKLES_PATH, fill: "currentColor")
        end
      end
    end

    def undo(template, class_name: nil)
      template.tag.span(class: class_names("f-c-ai-text-suggestions__undo-icon", class_name), aria: { hidden: true }) do
        template.tag.svg(class: "f-c-ai-text-suggestions__undo-svg",
                         fill: "none",
                         viewBox: "0 0 24 24",
                         xmlns: "http://www.w3.org/2000/svg") do
          template.tag.path(d: UNDO_PATH, fill: "currentColor")
        end
      end
    end

    private
      def class_names(*names)
        names.flatten.compact.map(&:to_s).reject(&:empty?).join(" ")
      end
  end
end
