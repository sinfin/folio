# frozen_string_literal: true

class Folio::Console::Tiptap::SimpleFormWrap::WordCountComponent < Folio::Console::ApplicationComponent
  def initialize(data: nil)
    @data = data || {}
  end

  def controller_data
    stimulus_merge(@data,
                  stimulus_controller("f-c-tiptap-simple-form-wrap-word-count",
                                      action: {
                                        "f-c-tiptap-simple-form-wrap:updateWordCount" => "updateWordCount",
                                      }))
  end
end
